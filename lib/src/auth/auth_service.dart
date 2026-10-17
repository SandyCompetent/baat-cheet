import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/secure_storage_service.dart';

/// Result wrapper for every AuthService call.
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult._({required this.success, this.errorMessage, this.user});

  factory AuthResult.ok([User? user]) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.err(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

class AuthService {
  static FirebaseAuth? _customAuth;
  static FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseFirestore? _customFirestore;
  static FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ── 1. Sign In with Email & Password ──────────────────────────────────────
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        final token = await cred.user!.getIdToken();
        if (token != null) {
          await SecureStorageService.saveUserToken(token);
        }
        await _updateUserDocument(cred.user!);
      }
      return AuthResult.ok(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Sign in failed: ${e.toString()}');
    }
  }

  // ── 2. Create Account ─────────────────────────────────────────────────────
  static Future<AuthResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await cred.user!.updateDisplayName(displayName.trim());
        await cred.user!.reload();
        final refreshed = auth.currentUser ?? cred.user!;
        final token = await refreshed.getIdToken();
        if (token != null) {
          await SecureStorageService.saveUserToken(token);
        }
        await _updateUserDocument(refreshed);
        return AuthResult.ok(refreshed);
      }
      return AuthResult.ok(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Account creation failed: ${e.toString()}');
    }
  }

  // ── 3. Passwordless / Email Link Sign-In ───────────────────────────────────
  static Future<AuthResult> sendSignInLink(String email) async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://chatbud-official.firebaseapp.com/login',
        handleCodeInApp: true,
        iOSBundleId: 'com.torvence.chatbud',
        androidPackageName: 'com.torvence.chatbud',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Could not send sign-in link: ${e.toString()}');
    }
  }

  // ── 4. Forgot Password / Reset Email ──────────────────────────────────────
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Password reset email failed: ${e.toString()}');
    }
  }

  // ── 5. Anonymous / Guest Sign-In ──────────────────────────────────────────
  static Future<AuthResult> signInAnonymously() async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final cred = await auth.signInAnonymously();
      return AuthResult.ok(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Anonymous sign-in failed: ${e.toString()}');
    }
  }

  // ── 6. User Document in Firestore ─────────────────────────────────────────
  static Future<void> _updateUserDocument(User user) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline fallback
    }
  }

  // ── 6. Mandatory Store Policy: Account Deletion ───────────────────────────
  /// Fully deletes the user account and associated personal data from Firestore.
  static Future<AuthResult> deleteAccount() async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final user = auth.currentUser;
      if (user == null) {
        return AuthResult.err('No user currently signed in.');
      }
      final uid = user.uid;

      // Clean up user document and profile data in Firestore
      final fs = _firestore;
      if (fs != null) {
        try {
          await fs.collection('users').doc(uid).delete();
        } catch (_) {}
      }

      // Delete Firebase Auth account
      await user.delete();
      await SecureStorageService.clearAll();
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.err(
          'For security, please sign out and sign back in before deleting your account.',
        );
      }
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Account deletion failed: ${e.toString()}');
    }
  }

  // ── 7. Sign Out ───────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      final uid = auth.currentUser?.uid;
      final fs = _firestore;
      if (uid != null && fs != null) {
        try {
          await fs.collection('users').doc(uid).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
      await auth.signOut();
      await SecureStorageService.clearAll();
    } catch (_) {}
  }

  static User? get currentUser => _auth?.currentUser;
  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream.value(null);

  // ── Firebase Error Mapper ─────────────────────────────────────────────────
  static String _message(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'That does not look like a valid email address.',
      'user-disabled' => 'This account has been disabled. Please contact support.',
      'user-not-found' => 'No account found for this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Incorrect email or password. Please try again.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password must be at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' => 'No internet connection. Please check your network.',
      'invalid-action-code' => 'The action code is invalid or has expired.',
      'expired-action-code' => 'This link or code has expired. Please request a new one.',
      _ => e.message ?? 'Authentication error. Please try again.',
    };
  }
}
