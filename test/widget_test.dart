import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/auth/unified_auth_screen.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/models/conversation.dart';
import 'package:chatbud/src/models/group_chat.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/group_page.dart';
import 'package:chatbud/src/screen/list_page.dart';
import 'package:chatbud/src/screen/message_page.dart';
import 'package:chatbud/src/screen/splash_screen.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/services/group_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'system',
      'saved_bookmarks': <String>[],
    });
    await StorageService.init();
  });

  group('Domain Models Tests', () {
    test('ChatMessage model creates, formats time, and serializes', () {
      final now = DateTime(2026, 10, 17, 14, 30);
      final msg = ChatMessage(
        id: 'msg_123',
        text: 'Hello Slate Theme',
        isUser: true,
        senderName: 'Bruce Wayne',
        timestamp: now,
        status: MessageStatus.delivered,
        isBookmarked: true,
      );

      expect(msg.id, 'msg_123');
      expect(msg.formattedTime, '14:30');
      expect(msg.isBookmarked, true);

      final map = msg.toMap();
      final fromMap = ChatMessage.fromMap(map);
      expect(fromMap.id, msg.id);
      expect(fromMap.text, msg.text);
      expect(fromMap.isBookmarked, true);
    });

    test('Conversation model copyWith works as expected', () {
      const conv = Conversation(
        id: 'conv_1',
        title: 'Gotham Chat',
        lastMessage: 'All clear',
        lastTime: '12:00',
        unreadCount: 2,
      );

      final updated = conv.copyWith(lastMessage: 'New alert', unreadCount: 0);
      expect(updated.lastMessage, 'New alert');
      expect(updated.unreadCount, 0);
      expect(updated.title, 'Gotham Chat');
    });

    test('GroupChat model serializes to and from map', () {
      const group = GroupChat(
        id: 'grp_test',
        name: 'Developers',
        description: 'Code discussions',
        memberCount: 42,
        lastActive: '1m ago',
        isJoined: true,
      );

      final map = group.toMap();
      final fromMap = GroupChat.fromMap(map);
      expect(fromMap.id, 'grp_test');
      expect(fromMap.memberCount, 42);
      expect(fromMap.isJoined, true);
    });
  });

  group('Service Layer Tests', () {
    test('ChatService sends messages and updates thread', () async {
      final service = ChatService.instance;
      final msg = await service.sendMessage(
        conversationId: 'ai_assistant',
        text: 'Test message',
        senderName: 'Tester',
      );

      expect(msg.text, 'Test message');
      final notifier = service.getMessagesNotifier('ai_assistant');
      expect(notifier.value.any((m) => m.text == 'Test message'), true);
    });

    test('GroupService creates and joins groups', () async {
      final service = GroupService.instance;
      final initialCount = service.groupsNotifier.value.length;

      final newGroup = await service.createGroup(
        name: 'Test Flutter Group',
        description: 'A test group for unit tests',
      );

      expect(service.groupsNotifier.value.length, initialCount + 1);
      expect(newGroup.name, 'Test Flutter Group');
      expect(newGroup.isJoined, true);

      service.toggleJoinGroup(newGroup.id);
      final toggled =
          service.groupsNotifier.value.firstWhere((g) => g.id == newGroup.id);
      expect(toggled.isJoined, false);
    });
  });

  group('Widget Tests', () {
    Widget buildTestApp(Widget home) {
      return MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        onGenerateRoute: RouteGenerator.generateRoute,
        home: home,
      );
    }

    testWidgets('SplashScreen renders and disposes cleanly without timer leaks',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const SplashScreen(redirectDelay: Duration(milliseconds: 50)),
        ),
      );
      expect(find.textContaining('ChatBud'), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('MessagePage renders filters and search field', (tester) async {
      await tester.pumpWidget(buildTestApp(const MessagePage()));

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('GroupPage displays groups and create button', (tester) async {
      await tester.pumpWidget(buildTestApp(const GroupPage()));

      expect(find.text('Groups'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('ListPage displays saved bookmarks correctly', (tester) async {
      await tester.pumpWidget(buildTestApp(const ListPage()));
      expect(find.text('Saved Messages'), findsOneWidget);
    });

    testWidgets('UnifiedAuthScreen renders email entry and buttons',
        (tester) async {
      await tester.pumpWidget(buildTestApp(const UnifiedAuthScreen()));

      expect(find.textContaining('ChatBud'), findsWidgets);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('ConversationScreen renders header and composer',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ConversationScreen(
            conversationId: 'ai_assistant',
            title: 'ChatBud AI Assistant',
            isAi: true,
          ),
        ),
      );

      expect(find.text('ChatBud AI Assistant'), findsOneWidget);
      expect(find.text('Type a message…'), findsOneWidget);
    });
  });
}
