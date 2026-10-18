import 'package:chatbud/src/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResult Tests', () {
    test('AuthResult.ok returns success state without errors', () {
      final result = AuthResult.ok();
      expect(result.success, true);
      expect(result.errorMessage, isNull);
      expect(result.user, isNull);
    });

    test('AuthResult.err returns failure state with message', () {
      const msg = 'Invalid password supplied';
      final result = AuthResult.err(msg);
      expect(result.success, false);
      expect(result.errorMessage, msg);
      expect(result.user, isNull);
    });
  });

  group('AuthService Method Tests', () {
    test('authenticateUnified returns error gracefully when Firebase is uninitialized', () async {
      final res = await AuthService.authenticateUnified(
        email: 'user@example.com',
        password: 'password123',
      );
      expect(res.success, false);
      expect(res.errorMessage, isNotNull);
    });

    test('signInWithGoogle returns error gracefully when Firebase is uninitialized', () async {
      final res = await AuthService.signInWithGoogle();
      expect(res.success, false);
      expect(res.errorMessage, isNotNull);
    });

    test('signInWithApple returns error gracefully when Firebase is uninitialized', () async {
      final res = await AuthService.signInWithApple();
      expect(res.success, false);
      expect(res.errorMessage, isNotNull);
    });
  });
}
