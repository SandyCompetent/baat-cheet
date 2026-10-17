import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service using platform Keychain (iOS/macOS) and Keystore (Android).
/// Replaces plain shared_preferences for any sensitive tokens or auth session keys.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _userTokenKey = 'auth_user_token';
  static const String _geminiApiKey = 'gemini_api_key';

  static Future<void> saveUserToken(String token) async {
    await _storage.write(key: _userTokenKey, value: token);
  }

  static Future<String?> getUserToken() async {
    return await _storage.read(key: _userTokenKey);
  }

  static Future<void> saveGeminiApiKey(String key) async {
    await _storage.write(key: _geminiApiKey, value: key);
  }

  static Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: _geminiApiKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
