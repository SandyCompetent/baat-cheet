import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// OtpManager — in-memory 6-digit OTP for new-account and forgot-password flows.
//
// Production note: Replace `_sendEmail` with a call to your Cloud Function
// that sends the code via SendGrid / Firebase Email Extension / Postmark.
// The verify() method then simply checks the code you stored server-side.
// Until then, the generated code is printed to the debug console so you can
// test the full step machine without a real email backend.
// ─────────────────────────────────────────────────────────────────────────────

enum OtpPurpose { newAccount, forgotPassword }

class OtpManager {
  OtpManager._();

  static String? _pendingEmail;
  static String? _pendingCode;
  static OtpPurpose? _pendingPurpose;
  static DateTime? _expiresAt;

  // ── Generate and "send" a new OTP ─────────────────────────────────────────
  static Future<String> send({
    required String email,
    required OtpPurpose purpose,
  }) async {
    final code = _generate();
    _pendingEmail   = email;
    _pendingCode    = code;
    _pendingPurpose = purpose;
    _expiresAt      = DateTime.now().add(const Duration(minutes: 10));

    // TODO: replace with Cloud Function / Email Extension call
    // ignore: avoid_print
    print('[OtpManager] OTP for $email ($purpose): $code (valid 10 min)');
    await Future.delayed(const Duration(milliseconds: 400)); // simulated network
    return code;
  }

  // ── Verify a submitted code ────────────────────────────────────────────────
  /// Returns null on success, or an error string on failure.
  static String? verify({
    required String email,
    required String code,
    required OtpPurpose purpose,
  }) {
    if (_pendingEmail   != email)   return 'OTP was not sent to this email.';
    if (_pendingPurpose != purpose) return 'Invalid OTP session.';
    if (_expiresAt == null || DateTime.now().isAfter(_expiresAt!)) {
      _clear();
      return 'This OTP has expired. Please request a new one.';
    }
    if (_pendingCode != code.trim()) return 'Incorrect code. Please try again.';
    _clear();
    return null; // success
  }

  // ── Peek at whether there is a live session ────────────────────────────────
  static bool get hasActivePending =>
      _pendingCode != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  static void _clear() {
    _pendingEmail   = null;
    _pendingCode    = null;
    _pendingPurpose = null;
    _expiresAt      = null;
  }

  static String _generate() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}
