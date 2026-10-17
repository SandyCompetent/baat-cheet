import 'package:chatbud/src/auth/otp_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpManager Tests', () {
    const testEmail = 'user@chatbud.com';

    test('send generates 6-digit OTP code and sets active session', () async {
      final code = await OtpManager.send(
        email: testEmail,
        purpose: OtpPurpose.newAccount,
      );

      expect(code.length, 6);
      expect(int.tryParse(code) != null, true);
      expect(OtpManager.hasActivePending, true);
    });

    test('verify succeeds when provided correct code, email, and purpose', () async {
      final code = await OtpManager.send(
        email: testEmail,
        purpose: OtpPurpose.newAccount,
      );

      final result = OtpManager.verify(
        email: testEmail,
        code: code,
        purpose: OtpPurpose.newAccount,
      );

      expect(result, isNull);
      expect(OtpManager.hasActivePending, false);
    });

    test('verify fails when provided incorrect code', () async {
      await OtpManager.send(
        email: testEmail,
        purpose: OtpPurpose.newAccount,
      );

      final result = OtpManager.verify(
        email: testEmail,
        code: '000000', // incorrect code
        purpose: OtpPurpose.newAccount,
      );

      expect(result, 'Incorrect code. Please try again.');
      expect(OtpManager.hasActivePending, true);
    });

    test('verify fails when provided mismatched email', () async {
      final code = await OtpManager.send(
        email: testEmail,
        purpose: OtpPurpose.newAccount,
      );

      final result = OtpManager.verify(
        email: 'other@chatbud.com',
        code: code,
        purpose: OtpPurpose.newAccount,
      );

      expect(result, 'OTP was not sent to this email.');
    });

    test('verify fails when provided mismatched purpose', () async {
      final code = await OtpManager.send(
        email: testEmail,
        purpose: OtpPurpose.newAccount,
      );

      final result = OtpManager.verify(
        email: testEmail,
        code: code,
        purpose: OtpPurpose.forgotPassword,
      );

      expect(result, 'Invalid OTP session.');
    });
  });
}
