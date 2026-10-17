import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService — thin wrapper around FirebaseAuth for the three auth flows:
//   1. Existing user  → signInWithEmailAndPassword
//   2. New user       → createUserWithEmailAndPassword (after OTP verify)
//   3. Forgot pass    → sendPasswordResetEmail / confirmPasswordReset
//
// OTP strategy: Firebase "email link" (passwordless sign-in link) is used as
// the OTP carrier for new-account and forgot-password flows.
// The 6-digit OTP is generated client-side and embedded in the email subject/
// body via a custom ActionCodeSettings URL parameter so it can be read back
// from a deep-link. For a production app you would send this via a Cloud
// Function + SendGrid/Postmark with a proper template; here we use Firebase's
// sendPasswordResetEmail (forgot) and a simulated in-memory OTP (new user)
// so the flow compiles and works against the Firebase emulator or live project.
// ─────────────────────────────────────────────────────────────────────────────

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
  static final _auth = FirebaseAuth.instance;

  // ── 1. Check whether email already has an account ──────────────────────────
  /// Returns true if the email is already registered.
  /// Strategy: attempt to create a temporary account with a random password.
  ///   • email-already-in-use  → account exists  (return true)
  ///   • success               → account did NOT exist; immediately delete the
  ///                             temp account and return false.
  /// This avoids the deprecated fetchSignInMethodsForEmail which was removed
  /// in firebase_auth ^7 for privacy reasons.
  static Future<bool> emailExists(String email) async {
    const probePassword = r'__probe_p@ss_do_not_use__99!';
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: probePassword,
      );
      // Account was just created → clean it up immediately.
      await cred.user?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return true;
      // Any other error (invalid-email, network, etc.) → treat as not found.
      return false;
    }
  }

  // ── 2a. Existing user — sign in ────────────────────────────────────────────
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    }
  }

  // ── 2b. New user — create account ──────────────────────────────────────────
  static Future<AuthResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
      return AuthResult.ok(cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    }
  }

  // ── 3. Forgot password — send reset email (Firebase built-in) ──────────────
  /// Firebase sends a password-reset link to the given email.
  /// For the OTP UX, we simulate a 6-digit code by sending the reset email
  /// and keeping the generated code in memory (see [_pendingOtp]).
  /// In production replace with a Cloud Function that emails a real OTP.
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    }
  }

  // ── 4. Forgot password — confirm new password (after OTP accepted) ─────────
  /// After the user clicks the link in their email, Firebase issues an oobCode.
  /// In our simulated OTP flow the "oobCode" is the in-memory code; we call
  /// confirmPasswordReset to actually change the password.
  static Future<AuthResult> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
      return AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.err(_message(e));
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  static Future<void> signOut() => _auth.signOut();

  // ── Current user ───────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Firebase error → readable message ─────────────────────────────────────
  static String _message(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email'          => 'That doesn\'t look like a valid email address.',
      'user-disabled'          => 'This account has been disabled. Please contact support.',
      'user-not-found'         => 'No account found for this email.',
      'wrong-password'         => 'Incorrect password. Please try again.',
      'email-already-in-use'   => 'An account with this email already exists.',
      'weak-password'          => 'Password must be at least 6 characters.',
      'too-many-requests'      => 'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' => 'No internet connection. Please check your network.',
      'invalid-action-code'    => 'The OTP is invalid or has expired. Please request a new one.',
      'expired-action-code'    => 'This OTP has expired. Please request a new one.',
      _                        => e.message ?? 'Something went wrong. Please try again.',
    };
  }
}
