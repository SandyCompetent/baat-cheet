import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-level local persistent storage using SharedPreferences.
/// Handles offline caching for:
/// - ThemeMode preference (system / light / dark)
/// - Saved/bookmarked message IDs
/// - Custom display name / guest credentials
/// - In-flight conversation drafts
class StorageService {
  static SharedPreferences? _prefs;

  static const String _themeKey = 'app_theme_mode';
  static const String _bookmarksKey = 'saved_bookmarks';
  static const String _guestNameKey = 'guest_display_name';
  static const String _customGroupsKey = 'custom_groups_json';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Theme Mode ────────────────────────────────────────────────────────────
  static String getThemeMode() {
    return _prefs?.getString(_themeKey) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(_themeKey, mode);
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────
  static Set<String> getBookmarks() {
    final list = _prefs?.getStringList(_bookmarksKey) ?? [];
    return list.toSet();
  }

  static Future<void> toggleBookmark(String messageId) async {
    final current = getBookmarks();
    if (current.contains(messageId)) {
      current.remove(messageId);
    } else {
      current.add(messageId);
    }
    await _prefs?.setStringList(_bookmarksKey, current.toList());
  }

  static bool isBookmarked(String messageId) {
    return getBookmarks().contains(messageId);
  }

  // ── Guest display name ────────────────────────────────────────────────────
  static String getGuestName() {
    return _prefs?.getString(_guestNameKey) ?? 'Guest User';
  }

  static Future<void> setGuestName(String name) async {
    await _prefs?.setString(_guestNameKey, name);
  }

  // ── Custom Groups Persistence ─────────────────────────────────────────────
  static List<Map<String, dynamic>> getSavedGroups() {
    final raw = _prefs?.getString(_customGroupsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGroups(List<Map<String, dynamic>> groups) async {
    await _prefs?.setString(_customGroupsKey, jsonEncode(groups));
  }
}
