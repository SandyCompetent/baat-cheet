import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Production-level local persistent storage using SharedPreferences.
/// Handles offline caching for:
/// - ThemeMode preference (system / light / dark)
/// - Saved/bookmarked message IDs
/// - Custom display name / guest credentials
/// - In-flight conversation drafts
/// - Cached conversation lists and message threads (offline & guest chat)
class StorageService {
  static SharedPreferences? _prefs;

  static const String _themeKey = 'app_theme_mode';
  static const String _bookmarksKey = 'saved_bookmarks';
  static const String _guestNameKey = 'guest_display_name';
  static const String _customGroupsKey = 'custom_groups_json';
  static const String _conversationsKey = 'cached_conversations_list';
  static const String _messagesPrefix = 'cached_messages_';

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

  // ── Conversation Messages Persistence ─────────────────────────────────────
  static List<ChatMessage> getConversationMessages(String conversationId) {
    final raw = _prefs?.getString('$_messagesPrefix$conversationId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveConversationMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    final list = messages.map((m) => m.toMap()).toList();
    await _prefs?.setString('$_messagesPrefix$conversationId', jsonEncode(list));
  }

  // ── Conversations List Persistence ────────────────────────────────────────
  static List<Conversation> getSavedConversations() {
    final raw = _prefs?.getString(_conversationsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Conversation.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveConversations(List<Conversation> conversations) async {
    final list = conversations.map((c) => c.toMap()).toList();
    await _prefs?.setString(_conversationsKey, jsonEncode(list));
  }
}
