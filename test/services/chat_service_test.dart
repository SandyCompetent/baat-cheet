import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('ChatService Tests', () {
    test('Initializes with default conversations', () {
      final service = ChatService.instance;
      final conversations = service.conversationsNotifier.value;

      expect(conversations.isNotEmpty, true);
      expect(conversations.any((c) => c.id == 'ai_assistant'), true);
      expect(conversations.any((c) => c.id == 'user_bruce'), true);
    });

    test('getMessagesNotifier retrieves or creates thread notifier', () {
      final service = ChatService.instance;
      final notifier = service.getMessagesNotifier('ai_assistant');

      expect(notifier.value.isNotEmpty, true);
      expect(notifier.value.first.senderName, 'ChatBud AI');
    });

    test('markAsRead zeroes out unread count for conversation', () {
      final service = ChatService.instance;
      // 'ai_assistant' has 1 unread message by default
      service.markAsRead('ai_assistant');

      final conv = service.conversationsNotifier.value
          .firstWhere((c) => c.id == 'ai_assistant');
      expect(conv.unreadCount, 0);
    });

    test('sendMessage adds message to thread and updates preview', () async {
      final service = ChatService.instance;
      final sent = await service.sendMessage(
        conversationId: 'user_bruce',
        text: 'Meeting at Wayne Tower',
        senderName: 'Alfred',
      );

      expect(sent.text, 'Meeting at Wayne Tower');
      expect(sent.senderName, 'Alfred');

      final notifier = service.getMessagesNotifier('user_bruce');
      expect(notifier.value.any((m) => m.id == sent.id), true);

      final topConv = service.conversationsNotifier.value.first;
      expect(topConv.id, 'user_bruce');
      expect(topConv.lastMessage, 'Meeting at Wayne Tower');
    });

    test('deleteMessage removes message from thread', () {
      final service = ChatService.instance;
      final notifier = service.getMessagesNotifier('user_bruce');
      final msgToDelete = notifier.value.first;

      service.deleteMessage('user_bruce', msgToDelete.id);

      expect(notifier.value.any((m) => m.id == msgToDelete.id), false);
    });

    test('toggleBookmark toggles message bookmark state and updates saved list', () async {
      final service = ChatService.instance;
      final notifier = service.getMessagesNotifier('user_bruce');
      final msg = notifier.value.first;
      final initialBookmarkState = msg.isBookmarked;

      await service.toggleBookmark(msg);

      expect(msg.isBookmarked, !initialBookmarkState);
      expect(
        service.savedMessagesNotifier.value.any((m) => m.id == msg.id),
        !initialBookmarkState,
      );
    });
  });
}
