import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/app_logger.dart';
import '../core/storage_service.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/persona.dart';
import 'gemini_service.dart';
import 'memory_service.dart';
import 'persona_service.dart';
import 'public_api_rag_service.dart';

/// Production-ready ChatService backed by Cloud Firestore.
/// Features:
/// - Real-time Firestore stream listeners for conversations and messages
/// - Infinite scroll pagination support with document cursors
/// - Online presence and real-time typing indicators
/// - User blocking and message reporting for Store UGC compliance
/// - Real-time streaming response engine for Gemini AI Assistant
/// - Offline caching and guest-mode local chat support without permission errors
class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal() {
    _loadCachedConversations();
  }

  void _loadCachedConversations() {
    try {
      final cached = StorageService.getSavedConversations();
      if (cached.isNotEmpty) {
        conversationsNotifier.value = cached;
      }
    } catch (_) {}
  }

  FirebaseFirestore? _customFirestore;
  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _canSyncFirestore {
    final fs = _firestore;
    if (fs == null) return false;
    return _currentUser != null;
  }

  @visibleForTesting
  set firestoreForTesting(FirebaseFirestore? fs) {
    _customFirestore = fs;
  }

  // Local reactive cache to ensure instant UI responsiveness and offline fallback
  final ValueNotifier<List<Conversation>> conversationsNotifier =
      ValueNotifier<List<Conversation>>([]);

  final Map<String, ValueNotifier<List<ChatMessage>>> _messagesNotifiers = {};
  final Map<String, StreamSubscription?> _conversationSubs = {};
  final Map<String, int> _messageLimits = {};
  final ValueNotifier<List<ChatMessage>> savedMessagesNotifier =
      ValueNotifier<List<ChatMessage>>([]);

  /// Tracks conversation IDs that are currently generating an AI response.
  final ValueNotifier<Set<String>> generatingConversationsNotifier =
      ValueNotifier<Set<String>>({});

  /// Returns true if [conversationId] currently has an AI response in-flight.
  bool isGenerating(String conversationId) =>
      generatingConversationsNotifier.value.contains(conversationId);

  final Set<String> _blockedUsers = {};

  bool isAiConversation(String conversationId) {
    if (conversationId == AppConstants.aiAssistantId ||
        conversationId.startsWith(AppConstants.aiPersonaPrefix)) {
      return true;
    }
    for (final c in conversationsNotifier.value) {
      if (c.id == conversationId && c.isAi) {
        return true;
      }
    }
    return false;
  }

  Future<Conversation> startPersonaConversation(Persona persona) async {
    final convId = '${AppConstants.aiPersonaPrefix}${persona.id}';
    final currentList = conversationsNotifier.value;
    final matchIdx = currentList.indexWhere((c) => c.id == convId);

    if (matchIdx != -1) {
      await PersonaService.instance.setActivePersona(persona.id);
      return currentList[matchIdx];
    }

    final newConv = Conversation(
      id: convId,
      title: persona.name,
      lastMessage: 'Tap to chat with ${persona.name}',
      lastTime: 'Now',
      isAi: true,
      personaId: persona.id,
    );

    final updated = [newConv, ...currentList];
    conversationsNotifier.value = updated;
    await StorageService.saveConversations(updated);
    await PersonaService.instance.setActivePersona(persona.id);
    return newConv;
  }

  // ── 1. Listen to Conversations ──────────────────────────────────────────
  Stream<List<Conversation>> streamConversations(String currentUserId) {
    final fs = _firestore;
    if (fs == null || !_canSyncFirestore) {
      return Stream.value(conversationsNotifier.value);
    }
    try {
      return fs
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          final isGroup = data['isGroup'] as bool? ?? false;
          final isAi = data['isAi'] as bool? ?? false;
          final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
          final unread = (unreadMap?[currentUserId] as num?)?.toInt() ?? 0;

          return Conversation(
            id: doc.id,
            title: data['title'] as String? ?? 'Conversation',
            lastMessage: data['lastMessage'] as String? ?? '',
            lastTime: data['lastTime'] as String? ?? '',
            unreadCount: unread,
            isAi: isAi,
            isGroup: isGroup,
          );
        }).toList();

        // Merge with existing local conversations (e.g. ai_assistant)
        final localOnly = conversationsNotifier.value
            .where((c) => c.isAi || !list.any((remote) => remote.id == c.id))
            .toList();

        final merged = [...localOnly, ...list];
        conversationsNotifier.value = merged;
        StorageService.saveConversations(merged);
        return merged;
      });
    } catch (_) {
      // Offline fallback
      return Stream.value(conversationsNotifier.value);
    }
  }

  // ── 2. Message Stream with Pagination ────────────────────────────────────
  ValueNotifier<List<ChatMessage>> getMessagesNotifier(String conversationId) {
    return _messagesNotifiers.putIfAbsent(conversationId, () {
      final cached = StorageService.getConversationMessages(conversationId);
      final notifier = ValueNotifier<List<ChatMessage>>(cached);
      if (!isAiConversation(conversationId) && _canSyncFirestore) {
        final currentLimit = _messageLimits[conversationId] ?? 40;
        _attachFirestoreMessageListener(conversationId, notifier,
            limit: currentLimit);
      }
      return notifier;
    });
  }

  /// Increments the pagination limit for a conversation and re-attaches the stream.
  void loadMoreMessages(String conversationId, {int batchSize = 20}) {
    if (isAiConversation(conversationId) || !_canSyncFirestore) return;
    final currentLimit = _messageLimits[conversationId] ?? 40;
    final newLimit = currentLimit + batchSize;
    _messageLimits[conversationId] = newLimit;

    final notifier = getMessagesNotifier(conversationId);
    _attachFirestoreMessageListener(conversationId, notifier, limit: newLimit);
  }

  void _attachFirestoreMessageListener(
    String conversationId,
    ValueNotifier<List<ChatMessage>> notifier, {
    int limit = 40,
  }) {
    if (isAiConversation(conversationId) || !_canSyncFirestore) return;
    _conversationSubs[conversationId]?.cancel();
    final fs = _firestore;
    if (fs == null) return;
    try {
      _conversationSubs[conversationId] = fs
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .listen(
        (snapshot) {
          // Query newest-first so the most recent `limit` messages are always
          // fetched (a growing thread must never drop new messages), then
          // reverse to chronological order (oldest-first) for display.
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data()..['id'] = doc.id))
              .where((m) => !_blockedUsers.contains(m.senderName))
              .toList()
              .reversed
              .toList();

          // Preserve in-flight local messages (e.g. streaming AI response)
          final inFlight = notifier.value
              .where((m) => !messages.any((docMsg) => docMsg.id == m.id))
              .toList();

          notifier.value = [...messages, ...inFlight];
          StorageService.saveConversationMessages(
              conversationId, notifier.value);
          _syncSavedMessages();
        },
        onError: (Object e, StackTrace st) {
          // Graceful handling when offline or rules pending, but observable.
          AppLogger.w(
            'Message stream error for conversation "$conversationId"',
            tag: 'ChatService',
            error: e,
            stackTrace: st,
          );
        },
      );
    } catch (_) {
      // Offline/test fallback
    }
  }

  // ── 3. Send Text Message (Restricted to Text Only) ───────────────────────
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    required String senderName,
    String? senderId,
  }) async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final message = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      senderName: senderName,
      timestamp: now,
      status: MessageStatus.delivered,
    );

    // Optimistically update local notifier
    final notifier = getMessagesNotifier(conversationId);
    notifier.value = [...notifier.value, message];
    _updateLocalConversationPreview(conversationId, text, timeStr,
        senderName: senderName);
    StorageService.saveConversationMessages(conversationId, notifier.value);

    // Heuristic fact extraction for two-layer memory engine
    _extractAndStoreUserMemories(text);

    // Persist to Cloud Firestore only if authenticated and not AI Assistant / Persona conversation
    if (!isAiConversation(conversationId) && _canSyncFirestore) {
      final fs = _firestore;
      if (fs != null) {
        try {
          final docRef = fs
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .doc(message.id);

          await docRef.set({
            'id': message.id,
            'text': message.text,
            'isUser': true,
            'senderName': senderName,
            'senderId': senderId ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'status': MessageStatus.delivered.name,
            'isBookmarked': false,
          });

          await fs.collection('conversations').doc(conversationId).set({
            'lastMessage': message.text,
            'lastTime': timeStr,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {
          // Offline fallback
        }
      }
    }

    // AI Assistant & Persona streaming logic
    if (isAiConversation(conversationId)) {
      Persona targetPersona =
          PersonaService.instance.activePersonaNotifier.value;
      if (conversationId.startsWith(AppConstants.aiPersonaPrefix)) {
        final pId =
            conversationId.replaceFirst(AppConstants.aiPersonaPrefix, '');
        targetPersona = PersonaService.instance.getPersonaById(pId);
      } else {
        for (final c in conversationsNotifier.value) {
          if (c.id == conversationId && c.personaId != null) {
            targetPersona =
                PersonaService.instance.getPersonaById(c.personaId!);
            break;
          }
        }
      }

      _streamPersonaResponse(
        conversationId: conversationId,
        persona: targetPersona,
        query: text,
        history: notifier.value,
      );
    } else {
      // Check for multi-agent @persona mentions in group channels
      _checkGroupPersonaMentions(conversationId, text, notifier.value);
    }

    return message;
  }

  // ── 4. Gemini AI & Multi-Agent Persona Streaming Engine ──────────────────
  void _extractAndStoreUserMemories(String text) {
    final lower = text.toLowerCase();
    final triggers = [
      'i like ',
      'i prefer ',
      'i love ',
      'i am building ',
      'i am working on ',
      'my goal is ',
      'my project is ',
      'i use ',
      'i am a ',
    ];
    for (final t in triggers) {
      if (lower.contains(t)) {
        MemoryService.instance.addMemory(
          fact: text.trim(),
          category: t.contains('building') ||
                  t.contains('working') ||
                  t.contains('project')
              ? 'project'
              : 'preference',
        );
        break;
      }
    }
  }

  void _checkGroupPersonaMentions(
    String conversationId,
    String text,
    List<ChatMessage> history,
  ) {
    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith('@')) {
        final persona = PersonaService.instance.findPersonaByName(word);
        if (persona != null) {
          _streamPersonaResponse(
            conversationId: conversationId,
            persona: persona,
            query: text,
            history: history,
          );
          break;
        }
      }
    }
  }

  void _streamPersonaResponse({
    required String conversationId,
    required Persona persona,
    required String query,
    required List<ChatMessage> history,
  }) async {
    generatingConversationsNotifier.value = {
      ...generatingConversationsNotifier.value,
      conversationId,
    };

    final aiMsgId =
        'msg_${persona.id}_${DateTime.now().millisecondsSinceEpoch}';
    final aiMessage = ChatMessage(
      id: aiMsgId,
      text: '',
      isUser: false,
      senderName: persona.name,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    final notifier = getMessagesNotifier(conversationId);
    notifier.value = [...notifier.value, aiMessage];

    final buffer = StringBuffer();
    List<Map<String, String>>? ragSources;

    try {
      // Live Grounded RAG Retrieval from Public APIs (OpenAlex, EndOfLife.date,
      // Google OSV, Arbeitnow, RemoteOK, Nager.Date, Datamuse, Wikipedia, etc.)
      final ragResult =
          await PublicApiRagService.instance.retrieveGroundingContext(
        personaId: persona.id,
        query: query,
        personaCategory: persona.category,
      );
      ragSources = ragResult.hasContext ? ragResult.toSourceMaps() : null;

      // Dynamic prompt injection with long-term memory, relationship state & live RAG
      final systemPrompt = MemoryService.instance.buildSystemPrompt(
        basePrompt: persona.systemPrompt,
        personaId: persona.id,
        currentQuery: query,
        ragContextBlock: ragResult.toSystemPromptBlock(),
      );

      final stream = GeminiService.instance.streamResponse(
        prompt: query,
        history: history,
        systemInstruction: systemPrompt,
        // Honor the user's currently selected model instead of hard-pinning the
        // default, so GeminiService.setModel() actually drives conversations.
        modelOverride: GeminiService.instance.currentModel,
      );

      await for (final token in stream) {
        buffer.write(token);
        final updatedList = List<ChatMessage>.from(notifier.value);
        final idx = updatedList.indexWhere((m) => m.id == aiMsgId);
        final streamingMsg = ChatMessage(
          id: aiMsgId,
          text: buffer.toString(),
          isUser: false,
          senderName: persona.name,
          timestamp: aiMessage.timestamp,
          status: MessageStatus.sending,
          ragSources: ragSources,
        );
        if (idx != -1) {
          updatedList[idx] = streamingMsg;
        } else {
          updatedList.add(streamingMsg);
        }
        notifier.value = updatedList;
      }

      // Mark final message as delivered once streaming finishes
      final finalList = List<ChatMessage>.from(notifier.value);
      final finalIdx = finalList.indexWhere((m) => m.id == aiMsgId);
      if (finalIdx != -1) {
        finalList[finalIdx] = ChatMessage(
          id: aiMsgId,
          text: buffer.toString(),
          isUser: false,
          senderName: persona.name,
          timestamp: aiMessage.timestamp,
          status: MessageStatus.delivered,
          ragSources: ragSources,
        );
        notifier.value = finalList;
      }

      final fullReply = buffer.toString();
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _updateLocalConversationPreview(conversationId, fullReply, timeStr,
          senderName: persona.name);
      StorageService.saveConversationMessages(conversationId, notifier.value);

      // Evolve relationship state
      await MemoryService.instance.recordInteraction(persona.id);
    } finally {
      final remaining = Set<String>.from(generatingConversationsNotifier.value)
        ..remove(conversationId);
      generatingConversationsNotifier.value = remaining;
    }
  }

  // ── 5. Real-Time Presence & Typing Indicators ────────────────────────────
  Future<void> setTypingStatus(
    String conversationId,
    String userId,
    bool isTyping,
  ) async {
    if (conversationId == AppConstants.aiAssistantId || !_canSyncFirestore) {
      return;
    }
    final fs = _firestore;
    if (fs == null) return;
    try {
      final docRef = fs.collection('conversations').doc(conversationId);
      if (isTyping) {
        await docRef.set({
          'typingUsers': FieldValue.arrayUnion([userId])
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'typingUsers': FieldValue.arrayRemove([userId])
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Stream<bool> listenTypingStatus(String conversationId, String currentUserId) {
    if (conversationId == AppConstants.aiAssistantId || !_canSyncFirestore) {
      return Stream.value(false);
    }
    final fs = _firestore;
    if (fs == null) return Stream.value(false);
    try {
      return fs
          .collection('conversations')
          .doc(conversationId)
          .snapshots()
          .map((snapshot) {
        final data = snapshot.data();
        if (data == null) return false;
        final typingList = (data['typingUsers'] as List<dynamic>?) ?? [];
        return typingList.any((uid) => uid != currentUserId);
      });
    } catch (_) {
      return Stream.value(false);
    }
  }

  // ── 6. Mandatory Store UGC Policy: Block & Report & Feedback ──────────────
  Future<bool> reportContent({
    required String reportedUserId,
    required String messageId,
    required String reason,
    required String messageText,
    String? reporterId,
  }) async {
    final user = _currentUser;
    final effectiveReporterId =
        (user != null && user.uid.isNotEmpty) ? user.uid : 'anonymous';

    final truncatedText = messageText.length > 5000
        ? messageText.substring(0, 5000)
        : messageText;

    // 1. Always store locally in StorageService as fallback & offline persistence
    try {
      await StorageService.saveLocalFeedback({
        'reportedUserId': reportedUserId,
        'messageId': messageId,
        'reason': reason,
        'messageText': truncatedText,
        'reporterId': effectiveReporterId,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending_review',
      });
    } catch (_) {}

    // 2. Persist to Cloud Firestore (works for authenticated AND unauthenticated users)
    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection('reports').add({
          'reportedUserId': reportedUserId,
          'messageId': messageId,
          'reason': reason,
          'messageText': truncatedText,
          'reporterId': effectiveReporterId,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending_review',
        });
        return true;
      } catch (e) {
        debugPrint('Firestore feedback submission failed: $e');
      }
    }
    return true;
  }

  void blockUser(String userId) {
    _blockedUsers.add(userId);
    // Filter currently loaded messages
    for (final notifier in _messagesNotifiers.values) {
      notifier.value =
          notifier.value.where((m) => m.senderName != userId).toList();
    }
  }

  bool isUserBlocked(String userId) => _blockedUsers.contains(userId);

  // ── 7. Message Bookmarking & Local Deletion ──────────────────────────────
  Future<void> toggleBookmark(ChatMessage message) async {
    message.isBookmarked = !message.isBookmarked;
    await StorageService.toggleBookmark(message.id);
    _syncSavedMessages();
  }

  void deleteMessage(String conversationId, String messageId) {
    final notifier = getMessagesNotifier(conversationId);
    notifier.value = notifier.value.where((m) => m.id != messageId).toList();
    _syncSavedMessages();
    StorageService.saveConversationMessages(conversationId, notifier.value);

    if (conversationId != AppConstants.aiAssistantId && _canSyncFirestore) {
      final fs = _firestore;
      if (fs != null) {
        try {
          fs
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .doc(messageId)
              .delete();
        } catch (_) {}
      }
    }
  }

  void markAsRead(String conversationId) {
    final list = List<Conversation>.from(conversationsNotifier.value);
    final idx = list.indexWhere((c) => c.id == conversationId);
    if (idx != -1 && list[idx].unreadCount > 0) {
      list[idx] = list[idx].copyWith(unreadCount: 0);
      conversationsNotifier.value = list;
      StorageService.saveConversations(list);
    }
  }

  void _syncSavedMessages() {
    final bookmarkedIds = StorageService.getBookmarks();
    final saved = <ChatMessage>[];

    for (final notifier in _messagesNotifiers.values) {
      for (final msg in notifier.value) {
        if (bookmarkedIds.contains(msg.id)) {
          msg.isBookmarked = true;
          saved.add(msg);
        }
      }
    }
    savedMessagesNotifier.value = saved;
  }

  void _updateLocalConversationPreview(
    String conversationId,
    String lastText,
    String timeStr, {
    String? senderName,
  }) {
    final list = List<Conversation>.from(conversationsNotifier.value);
    final idx = list.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        lastMessage: lastText,
        lastTime: timeStr,
      );
      final item = list.removeAt(idx);
      list.insert(0, item);
      conversationsNotifier.value = list;
    } else {
      // Add conversation if not present
      final isAi = conversationId == AppConstants.aiAssistantId ||
          conversationId.startsWith(AppConstants.aiPersonaPrefix);
      String title = isAi ? 'ChatBud AI Assistant' : 'Chat';
      if (conversationId.startsWith(AppConstants.aiPersonaPrefix)) {
        final pId =
            conversationId.replaceFirst(AppConstants.aiPersonaPrefix, '');
        title = PersonaService.instance.getPersonaById(pId).name;
      } else if (senderName != null &&
          senderName.isNotEmpty &&
          senderName != 'User' &&
          senderName != 'Guest User') {
        title = senderName;
      }
      final newConv = Conversation(
        id: conversationId,
        title: title,
        lastMessage: lastText,
        lastTime: timeStr,
        isAi: isAi,
        personaId: conversationId.startsWith('ai_persona_')
            ? conversationId.replaceFirst('ai_persona_', '')
            : null,
      );
      conversationsNotifier.value = [newConv, ...list];
    }
    StorageService.saveConversations(conversationsNotifier.value);
  }
}
