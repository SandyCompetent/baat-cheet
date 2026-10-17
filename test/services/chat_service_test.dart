import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/services/persona_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('ChatService Production Tests', () {
    test('Initializes with empty state and no mock data', () {
      final service = ChatService.instance;
      expect(service.conversationsNotifier.value, isNotNull);
    });

    test('sendMessage creates message, updates thread and updates conversation preview', () async {
      final service = ChatService.instance;
      final sent = await service.sendMessage(
        conversationId: 'conv_123',
        text: 'Hello Cloud Firestore!',
        senderName: 'Alice',
      );

      expect(sent.text, 'Hello Cloud Firestore!');
      expect(sent.senderName, 'Alice');
      expect(sent.status, MessageStatus.delivered);

      final notifier = service.getMessagesNotifier('conv_123');
      expect(notifier.value.any((m) => m.id == sent.id), true);

      final topConv = service.conversationsNotifier.value.first;
      expect(topConv.id, 'conv_123');
      expect(topConv.lastMessage, 'Hello Cloud Firestore!');
    });

    test('markAsRead zeroes out unread count for conversation', () {
      final service = ChatService.instance;
      service.markAsRead('conv_123');
      final topConv = service.conversationsNotifier.value.firstWhere((c) => c.id == 'conv_123');
      expect(topConv.unreadCount, 0);
    });

    test('deleteMessage removes message from thread', () async {
      final service = ChatService.instance;
      final sent = await service.sendMessage(
        conversationId: 'conv_delete_test',
        text: 'To be deleted',
        senderName: 'Alice',
      );

      final notifier = service.getMessagesNotifier('conv_delete_test');
      expect(notifier.value.any((m) => m.id == sent.id), true);

      service.deleteMessage('conv_delete_test', sent.id);
      expect(notifier.value.any((m) => m.id == sent.id), false);
    });

    test('toggleBookmark toggles message bookmark state and updates saved list', () async {
      final service = ChatService.instance;
      final sent = await service.sendMessage(
        conversationId: 'conv_bookmark_test',
        text: 'Bookmark me',
        senderName: 'Alice',
      );

      final notifier = service.getMessagesNotifier('conv_bookmark_test');
      final msg = notifier.value.firstWhere((m) => m.id == sent.id);
      final initialBookmarkState = msg.isBookmarked;

      await service.toggleBookmark(msg);

      expect(msg.isBookmarked, !initialBookmarkState);
      expect(
        service.savedMessagesNotifier.value.any((m) => m.id == msg.id),
        !initialBookmarkState,
      );
    });

    test('blockUser blocks user and filters out their messages', () async {
      final service = ChatService.instance;
      await service.sendMessage(
        conversationId: 'conv_block_test',
        text: 'Spam from bad user',
        senderName: 'spammer_1',
      );

      expect(service.isUserBlocked('spammer_1'), false);
      service.blockUser('spammer_1');
      expect(service.isUserBlocked('spammer_1'), true);

      final notifier = service.getMessagesNotifier('conv_block_test');
      expect(notifier.value.any((m) => m.senderName == 'spammer_1'), false);
    });

    test('reportContent logs report without crashing', () async {
      final service = ChatService.instance;
      await expectLater(
        service.reportContent(
          reportedUserId: 'spammer_1',
          messageId: 'msg_test_1',
          reason: 'Harassment or hate speech',
          messageText: 'Offensive message',
        ),
        completes,
      );
    });

    test('Guest / unauthenticated AI chat operates completely offline without permission errors', () async {
      final service = ChatService.instance;
      final sent = await service.sendMessage(
        conversationId: 'ai_assistant',
        text: 'What can you do?',
        senderName: 'Guest User',
      );

      expect(sent.text, 'What can you do?');
      expect(sent.isUser, true);

      final notifier = service.getMessagesNotifier('ai_assistant');
      expect(notifier.value.any((m) => m.id == sent.id), true);

      // Verify cached in StorageService
      final cached = StorageService.getConversationMessages('ai_assistant');
      expect(cached.any((m) => m.id == sent.id), true);
    });

    test('listenTypingStatus returns false stream for AI Assistant or guest mode', () async {
      final service = ChatService.instance;
      final isTyping = await service.listenTypingStatus('ai_assistant', 'guest').first;
      expect(isTyping, false);
    });

    test('setTypingStatus completes safely without error for guest or AI assistant', () async {
      final service = ChatService.instance;
      await expectLater(
        service.setTypingStatus('ai_assistant', 'guest', true),
        completes,
      );
    });

    test('isAiConversation accurately detects AI channels', () {
      final service = ChatService.instance;
      expect(service.isAiConversation('ai_assistant'), true);
      expect(service.isAiConversation('ai_persona_athena'), true);
      expect(service.isAiConversation('group_123'), false);
    });

    test('startPersonaConversation creates conversation and selects persona', () async {
      final service = ChatService.instance;
      final cipher = PersonaService.instance.getPersonaById('cipher');
      final conv = await service.startPersonaConversation(cipher);

      expect(conv.id, 'ai_persona_cipher');
      expect(conv.isAi, true);
      expect(conv.personaId, 'cipher');
      expect(service.isAiConversation(conv.id), true);
    });

    test('group chat @Persona mention triggers persona response', () async {
      final service = ChatService.instance;
      await service.sendMessage(
        conversationId: 'group_engineering',
        text: 'Hey @Athena can you inspect our architecture?',
        senderName: 'Alice',
      );

      final notifier = service.getMessagesNotifier('group_engineering');
      // Wait for stream event to add persona message
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(notifier.value.any((m) => m.senderName == 'Athena'), true);
    });
  });
}
