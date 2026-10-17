import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/storage_service.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Production-ready chat management service.
/// Provides reactive streams and notifiers for:
/// - Active conversations and unread counts
/// - Per-thread message feeds with optimistic sending
/// - Message bookmarking & saved items sync
/// - AI Assistant bot response engine
class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal() {
    _initDefaultData();
  }

  final ValueNotifier<List<Conversation>> conversationsNotifier =
      ValueNotifier<List<Conversation>>([]);

  final Map<String, ValueNotifier<List<ChatMessage>>> _messagesNotifiers = {};

  final ValueNotifier<List<ChatMessage>> savedMessagesNotifier =
      ValueNotifier<List<ChatMessage>>([]);

  void _initDefaultData() {
    final initialConversations = [
      const Conversation(
        id: 'ai_assistant',
        title: 'ChatBud AI Assistant',
        lastMessage: 'How can I assist you today? Tap to chat!',
        lastTime: 'Now',
        unreadCount: 1,
        isAi: true,
      ),
      const Conversation(
        id: 'user_bruce',
        title: 'Bruce Wayne',
        lastMessage: 'The Bat-Signal is on. Meeting tonight.',
        lastTime: '10:00',
        unreadCount: 0,
      ),
      const Conversation(
        id: 'user_oswald',
        title: 'Oswald Cobblepot',
        lastMessage: 'The Iceberg Lounge opens at midnight.',
        lastTime: '08:30',
        unreadCount: 0,
      ),
      const Conversation(
        id: 'user_fish',
        title: 'Fish Mooney',
        lastMessage: 'Keep your friends close, my dear.',
        lastTime: 'Yesterday',
        unreadCount: 0,
      ),
      const Conversation(
        id: 'user_barbara',
        title: 'Barbara Kean',
        lastMessage: 'Did you hear about the new gallery opening?',
        lastTime: 'Oct 15',
        unreadCount: 0,
      ),
    ];
    conversationsNotifier.value = initialConversations;

    // Seed default messages for AI Assistant
    _getOrCreateNotifier('ai_assistant').value = [
      ChatMessage(
        id: 'ai_welcome_1',
        text: 'Hello! I am ChatBud AI Assistant, your 24/7 intelligent companion. Ask me anything or start chatting right away!',
        isUser: false,
        senderName: 'ChatBud AI',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.read,
      ),
    ];

    // Seed default messages for Bruce
    _getOrCreateNotifier('user_bruce').value = [
      ChatMessage(
        id: 'bruce_1',
        text: 'Are you in town this weekend?',
        isUser: false,
        senderName: 'Bruce Wayne',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'bruce_2',
        text: 'The Bat-Signal is on. Meeting tonight.',
        isUser: false,
        senderName: 'Bruce Wayne',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        status: MessageStatus.read,
      ),
    ];

    _syncSavedMessages();
  }

  ValueNotifier<List<ChatMessage>> getMessagesNotifier(String conversationId) {
    return _getOrCreateNotifier(conversationId);
  }

  ValueNotifier<List<ChatMessage>> _getOrCreateNotifier(String conversationId) {
    return _messagesNotifiers.putIfAbsent(
      conversationId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  void markAsRead(String conversationId) {
    final list = List<Conversation>.from(conversationsNotifier.value);
    final idx = list.indexWhere((c) => c.id == conversationId);
    if (idx != -1 && list[idx].unreadCount > 0) {
      list[idx] = list[idx].copyWith(unreadCount: 0);
      conversationsNotifier.value = list;
    }
  }

  /// Sends a message into a thread optimistically and triggers responses if AI
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
    required String senderName,
    AttachmentType attachmentType = AttachmentType.none,
    String? attachmentName,
  }) async {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      senderName: senderName,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachmentType: attachmentType,
      attachmentName: attachmentName,
    );

    final notifier = _getOrCreateNotifier(conversationId);
    notifier.value = [...notifier.value, message];

    // Update conversation list preview
    _updateConversationPreview(conversationId, text);

    // Simulate network delivery
    Future.delayed(const Duration(milliseconds: 350), () {
      message.status = MessageStatus.delivered;
      notifier.value = List<ChatMessage>.from(notifier.value);
    });

    // If AI Assistant conversation, trigger automated AI response
    if (conversationId == 'ai_assistant') {
      _triggerAiResponse(conversationId, text);
    }

    return message;
  }

  void deleteMessage(String conversationId, String messageId) {
    final notifier = _getOrCreateNotifier(conversationId);
    notifier.value = notifier.value.where((m) => m.id != messageId).toList();
    _syncSavedMessages();
  }

  Future<void> toggleBookmark(ChatMessage message) async {
    message.isBookmarked = !message.isBookmarked;
    await StorageService.toggleBookmark(message.id);
    _syncSavedMessages();
    // Notify thread
    _messagesNotifiers.forEach((_, notifier) {
      if (notifier.value.any((m) => m.id == message.id)) {
        notifier.value = List<ChatMessage>.from(notifier.value);
      }
    });
  }

  void _syncSavedMessages() {
    final bookmarkedIds = StorageService.getBookmarks();
    final saved = <ChatMessage>[];

    for (final notifier in _messagesNotifiers.values) {
      for (final msg in notifier.value) {
        if (bookmarkedIds.contains(msg.id) || msg.isBookmarked) {
          msg.isBookmarked = true;
          saved.add(msg);
        }
      }
    }
    savedMessagesNotifier.value = saved;
  }

  void _updateConversationPreview(String conversationId, String lastText) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final list = List<Conversation>.from(conversationsNotifier.value);
    final idx = list.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        lastMessage: lastText,
        lastTime: timeStr,
      );
      // Bring active conversation to top of list
      final item = list.removeAt(idx);
      list.insert(0, item);
      conversationsNotifier.value = list;
    }
  }

  void _triggerAiResponse(String conversationId, String query) {
    Future.delayed(const Duration(milliseconds: 900), () {
      final replyText = _generateAiAnswer(query);
      final aiMessage = ChatMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        text: replyText,
        isUser: false,
        senderName: 'ChatBud AI',
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      );

      final notifier = _getOrCreateNotifier(conversationId);
      notifier.value = [...notifier.value, aiMessage];
      _updateConversationPreview(conversationId, replyText);
    });
  }

  String _generateAiAnswer(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return 'Hello! How can I make your day more productive?';
    } else if (lower.contains('help') || lower.contains('features')) {
      return 'ChatBud features: Real-time messaging, Slate theme with OLED dark mode, group chats, bookmarks, message attachments, and unified authentication.';
    } else if (lower.contains('who are you') || lower.contains('name')) {
      return 'I am ChatBud AI, your intelligent assistant built into this workspace.';
    } else if (lower.contains('theme') || lower.contains('slate')) {
      return 'The Soft Minimalist Slate theme pairs cool slate neutrals with Electric Indigo (#4F46E5 / #6366F1) for maximum legibility and zero glare.';
    } else {
      return 'Got it! I processed "$query". Is there anything else you would like to explore or do?';
    }
  }
}
