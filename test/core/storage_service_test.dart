import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'dark',
      'saved_bookmarks': <String>['msg_1', 'msg_2'],
      'guest_display_name': 'Batman',
    });
    await StorageService.init();
  });

  group('StorageService Tests', () {
    test('getThemeMode reads stored theme preference', () {
      expect(StorageService.getThemeMode(), 'dark');
    });

    test('setThemeMode updates theme preference', () async {
      await StorageService.setThemeMode('light');
      expect(StorageService.getThemeMode(), 'light');
    });

    test('getBookmarks returns initial list of saved bookmark IDs', () {
      final bookmarks = StorageService.getBookmarks();
      expect(bookmarks.contains('msg_1'), true);
      expect(bookmarks.contains('msg_2'), true);
      expect(bookmarks.length, 2);
    });

    test('toggleBookmark adds and removes message ID from bookmarks', () async {
      // Toggle new message ID -> should be added
      await StorageService.toggleBookmark('msg_3');
      expect(StorageService.isBookmarked('msg_3'), true);

      // Toggle existing message ID -> should be removed
      await StorageService.toggleBookmark('msg_3');
      expect(StorageService.isBookmarked('msg_3'), false);
    });

    test('getGuestName and setGuestName manage guest user display name',
        () async {
      expect(StorageService.getGuestName(), 'Batman');

      await StorageService.setGuestName('Bruce Wayne');
      expect(StorageService.getGuestName(), 'Bruce Wayne');
    });

    test('getSavedGroups and saveGroups handle group JSON storage', () async {
      expect(StorageService.getSavedGroups(), isEmpty);

      final groupsData = [
        {
          'id': 'custom_1',
          'name': 'Custom Group 1',
          'description': 'Custom Description',
          'memberCount': 5,
          'lastActive': 'Now',
          'isJoined': true,
        }
      ];

      await StorageService.saveGroups(groupsData);
      final saved = StorageService.getSavedGroups();
      expect(saved.length, 1);
      expect(saved.first['name'], 'Custom Group 1');
      expect(saved.first['isJoined'], true);
    });

    test(
        'getConversationMessages and saveConversationMessages persist messages locally',
        () async {
      expect(StorageService.getConversationMessages('ai_assistant'), isEmpty);

      final testMsgs = [
        ChatMessage(
          id: 'test_msg_1',
          text: 'Hello AI',
          isUser: true,
          senderName: 'Guest',
          timestamp: DateTime.now(),
        ),
      ];

      await StorageService.saveConversationMessages('ai_assistant', testMsgs);
      final loaded = StorageService.getConversationMessages('ai_assistant');
      expect(loaded.length, 1);
      expect(loaded.first.id, 'test_msg_1');
      expect(loaded.first.text, 'Hello AI');
    });

    test(
        'getSavedConversations and saveConversations persist conversations locally',
        () async {
      expect(StorageService.getSavedConversations(), isEmpty);

      final testConvs = [
        const Conversation(
          id: 'ai_assistant',
          title: 'ChatBud AI Assistant',
          lastMessage: 'Hello there!',
          lastTime: '12:00',
          isAi: true,
        ),
      ];

      await StorageService.saveConversations(testConvs);
      final loaded = StorageService.getSavedConversations();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'ai_assistant');
      expect(loaded.first.title, 'ChatBud AI Assistant');
    });

    test('saveLocalFeedback and getStoredFeedback persist feedback offline',
        () async {
      expect(StorageService.getStoredFeedback(), isEmpty);

      final feedback = {
        'reportedUserId': 'system',
        'messageId': 'fb_1',
        'reason': 'User Feedback',
        'messageText': 'Loving ChatBud so far!',
        'reporterId': 'anonymous',
        'status': 'pending_review',
      };

      await StorageService.saveLocalFeedback(feedback);
      final list = StorageService.getStoredFeedback();
      expect(list.length, 1);
      expect(list.first['messageText'], 'Loving ChatBud so far!');
      expect(list.first['reporterId'], 'anonymous');
    });

    test('BYOK API key and Gemini model preferences persist and clear',
        () async {
      expect(StorageService.getCustomApiKey(), isNull);
      await StorageService.setCustomApiKey('AIzaSyExampleKey');
      expect(StorageService.getCustomApiKey(), 'AIzaSyExampleKey');

      await StorageService.setCustomApiKey('');
      expect(StorageService.getCustomApiKey(), isNull);

      await StorageService.setSelectedModel('gemini-2.5-pro');
      expect(StorageService.getSelectedModel(), 'gemini-2.5-pro');

      await StorageService.setAvailableModels(
          ['gemini-2.5-flash', 'gemini-2.5-pro']);
      expect(StorageService.getAvailableModels(),
          ['gemini-2.5-flash', 'gemini-2.5-pro']);
    });
  });
}
