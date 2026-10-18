import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/app_state.dart';
import '../core/app_logger.dart';
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

  // ── Unified Authentication (Login or Auto-Register) ─────────────────────────
  /// Unified authentication flow for single login/signup forms:
  /// 1. Tries to sign in with email and password.
  /// 2. If the user does not exist (`user-not-found` or `invalid-credential` with email enumeration protection),
  ///    it automatically provisions a new account via `createUserWithEmailAndPassword`.
  /// 3. If creation throws `email-already-in-use`, it indicates the user exists but
  ///    entered the wrong password, surfacing a precise error message.
  static Future<AuthResult> authenticateUnified({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }

    final trimmedEmail = email.trim();
    final effectiveName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : trimmedEmail.split('@').first;

    try {
      // Step 1: Attempt to sign in
      final cred = await auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        await _postSocialSignIn(user);
        return AuthResult.ok(user);
      }
      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      // Step 2: Handle user not found / seamless auto-creation
      if (e.code == 'user-not-found') {
        return createAccount(
          email: trimmedEmail,
          password: password,
          displayName: effectiveName,
        );
      }

      // Modern Firebase Email Enumeration Protection throws 'invalid-credential'
      // for BOTH unknown email AND incorrect password.
      if (e.code == 'invalid-credential') {
        try {
          final registerResult = await auth.createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: password,
          );
          final user = registerResult.user;
          if (user != null) {
            await user.updateDisplayName(effectiveName);
            await user.reload();
            final refreshed = auth.currentUser ?? user;
            await _postSocialSignIn(refreshed);
            return AuthResult.ok(refreshed);
          }
          return AuthResult.ok(user);
        } on FirebaseAuthException catch (regError) {
          if (regError.code == 'email-already-in-use') {
            // User exists, but the password provided was wrong
            return AuthResult.err(
              'Incorrect password for this account. Please try again or reset your password.',
            );
          }
          return AuthResult.err(_message(regError));
        } catch (_) {
          return AuthResult.err('Incorrect email or password. Please try again.');
        }
      }

      return AuthResult.err(_message(e));
    } catch (e) {
      final str = e.toString();
      if (str.contains('CONFIGURATION_NOT_FOUND')) {
        return AuthResult.err(
          'Firebase Authentication is not enabled for this project yet. Please open the Firebase Console (Build > Authentication > Sign-in method), click "Get Started", and enable "Email/Password".',
        );
      }
      return AuthResult.err('Authentication failed: $str');
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
      final str = e.toString();
      if (str.contains('CONFIGURATION_NOT_FOUND')) {
        return AuthResult.err(
          'Firebase Authentication is not enabled for this project yet. Please open the Firebase Console (Build > Authentication > Sign-in method), click "Get Started", and enable "Email/Password".',
        );
      }
      return AuthResult.err('Sign in failed: $str');
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
      final str = e.toString();
      if (str.contains('CONFIGURATION_NOT_FOUND')) {
        return AuthResult.err(
          'Firebase Authentication is not enabled for this project yet. Please open the Firebase Console (Build > Authentication > Sign-in method), click "Get Started", and enable "Email/Password".',
        );
      }
      return AuthResult.err('Account creation failed: $str');
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
    final userDoc = fs.collection('users').doc(user.uid);
    try {
      // Ensure displayName is never empty and does not exceed 100 characters to satisfy Firestore rules.
      String effectiveName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'User');
      if (effectiveName.length > 100) {
        effectiveName = effectiveName.substring(0, 100);
      }

      // Public profile — readable by any authenticated user for discovery.
      // NOTE: email is deliberately NOT stored here; see the private subdoc
      // below and the field-privacy rationale in firestore.rules.
      await userDoc.set({
        'uid': user.uid,
        'displayName': effectiveName,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Private contact info — readable/writable only by the owner.
      await userDoc.collection('private').doc('me').set({
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.w('Failed to update user document',
          tag: 'AuthService', error: e, stackTrace: st);
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
          // Remove the private subdoc first (Firestore does not cascade
          // subcollection deletes), then the public profile document.
          await fs.collection('users').doc(uid).collection('private').doc('me').delete();
          await fs.collection('users').doc(uid).delete();
        } catch (e, st) {
          AppLogger.w('Failed to delete user documents during account deletion',
              tag: 'AuthService', error: e, stackTrace: st);
        }
      }

      // Delete Firebase Auth account
      await user.delete();
      await SecureStorageService.clearAll();
      await AppState.instance.signOut();
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

  // ── 8. Sign In with Google ────────────────────────────────────────────────
  static Future<AuthResult> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        // Fallback for web or desktop where GoogleSignIn plugin delegates to provider
        try {
          final cred = await auth.signInWithProvider(GoogleAuthProvider());
          final user = cred.user;
          if (user != null) {
            await _postSocialSignIn(user);
            return AuthResult.ok(user);
          }
        } catch (_) {}
        return AuthResult.err('Google sign-in is not supported on this platform: ${e.toString()}');
      }

      if (googleUser == null) {
        return AuthResult.err('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await auth.signInWithCredential(credential);
      final user = cred.user;
      if (user != null) {
        await _postSocialSignIn(user);
        return AuthResult.ok(user);
      }
      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      return AuthResult.err('Google sign-in failed: ${e.toString()}');
    }
  }

  // ── 9. Sign In with Apple ─────────────────────────────────────────────────
  static Future<AuthResult> signInWithApple() async {
    final auth = _auth;
    if (auth == null) {
      return AuthResult.err('Firebase is not initialized.');
    }
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final cred = await auth.signInWithCredential(oauthCredential);
      final user = cred.user;
      if (user != null) {
        if (appleCredential.givenName != null &&
            (user.displayName == null || user.displayName!.isEmpty)) {
          final name = [appleCredential.givenName, appleCredential.familyName]
              .where((p) => p != null && p.isNotEmpty)
              .join(' ');
          if (name.isNotEmpty) {
            await user.updateDisplayName(name);
          }
        }
        await _postSocialSignIn(user);
        return AuthResult.ok(user);
      }
      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    } catch (e) {
      // Fallback for Web / desktop: OAuthProvider flow
      try {
        final cred = await auth.signInWithProvider(OAuthProvider('apple.com'));
        final user = cred.user;
        if (user != null) {
          await _postSocialSignIn(user);
          return AuthResult.ok(user);
        }
      } catch (_) {}
      return AuthResult.err('Apple sign-in failed: ${e.toString()}');
    }
  }

  static Future<void> _postSocialSignIn(User user) async {
    final token = await user.getIdToken();
    if (token != null) {
      await SecureStorageService.saveUserToken(token);
    }
    await _updateUserDocument(user);
  }

  static User? get currentUser => _auth?.currentUser;
  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? Stream.value(null);

  // ── Firebase Error Mapper ─────────────────────────────────────────────────
  static String _message(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final msg = e.message ?? '';

    if (code == 'configuration-not-found' ||
        msg.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication is not enabled for this project yet. Please open the Firebase Console (Build > Authentication > Sign-in method), click "Get Started", and enable "Email/Password".';
    }
    if (code == 'operation-not-allowed') {
      return 'Email/Password sign-in is disabled in Firebase Console. Please enable it under Build > Authentication > Sign-in method.';
    }

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
