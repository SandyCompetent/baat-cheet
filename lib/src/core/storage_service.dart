import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/persona.dart';
import '../models/user_memory.dart';
import '../models/relationship_state.dart';

/// Production-level local persistent storage using SharedPreferences.
/// Handles offline caching for:
/// - ThemeMode preference (system / light / dark)
/// - Saved/bookmarked message IDs
/// - Custom display name / guest credentials
/// - In-flight conversation drafts
/// - Cached conversation lists and message threads (offline & guest chat)
/// - Custom Personas, Long-term Memories, and Relationship States
class StorageService {
  static SharedPreferences? _prefs;

  static const String _themeKey = 'app_theme_mode';
  static const String _bookmarksKey = 'saved_bookmarks';
  static const String _guestNameKey = 'guest_display_name';
  static const String _customGroupsKey = 'custom_groups_json';
  static const String _conversationsKey = 'cached_conversations_list';
  static const String _messagesPrefix = 'cached_messages_';
  static const String _customPersonasKey = 'custom_personas_json';
  static const String _userMemoriesKey = 'user_memories_json';
  static const String _relationshipStatesKey = 'relationship_states_json';
  static const String _activePersonaKey = 'active_persona_id';

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

  // ── Custom Personas Persistence ───────────────────────────────────────────
  static List<Persona> getSavedPersonas() {
    final raw = _prefs?.getString(_customPersonasKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Persona.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePersonas(List<Persona> personas) async {
    final list = personas.map((p) => p.toMap()).toList();
    await _prefs?.setString(_customPersonasKey, jsonEncode(list));
  }

  static String? getActivePersonaId() {
    return _prefs?.getString(_activePersonaKey);
  }

  static Future<void> setActivePersonaId(String? id) async {
    if (id == null) {
      await _prefs?.remove(_activePersonaKey);
    } else {
      await _prefs?.setString(_activePersonaKey, id);
    }
  }

  // ── User Memories Persistence ─────────────────────────────────────────────
  static List<UserMemory> getUserMemories() {
    final raw = _prefs?.getString(_userMemoriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => UserMemory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveUserMemories(List<UserMemory> memories) async {
    final list = memories.map((m) => m.toMap()).toList();
    await _prefs?.setString(_userMemoriesKey, jsonEncode(list));
  }

  // ── Relationship States Persistence ───────────────────────────────────────
  static Map<String, RelationshipState> getRelationshipStates() {
    final raw = _prefs?.getString(_relationshipStatesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          RelationshipState.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveRelationshipStates(
    Map<String, RelationshipState> states,
  ) async {
    final map = states.map((k, v) => MapEntry(k, v.toMap()));
    await _prefs?.setString(_relationshipStatesKey, jsonEncode(map));
  }
}
