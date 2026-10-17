import 'package:chatbud/src/core/storage_service.dart';
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

    test('getGuestName and setGuestName manage guest user display name', () async {
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
  });
}
