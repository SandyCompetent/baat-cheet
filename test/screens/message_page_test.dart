import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/message_page.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    ChatService.instance.conversationsNotifier.value = [];
  });

  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const MessagePage(),
    );
  }

  group('MessagePage Widget Tests', () {
    testWidgets(
        'Renders app title and clean empty state without filter tabs when no chats exist',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      // Filter tabs are hidden when no conversations exist
      expect(find.text('All'), findsNothing);
      expect(find.text('Unread'), findsNothing);
      expect(find.text('No conversations found'), findsOneWidget);
      expect(find.text('Chat with AI Assistant'), findsOneWidget);
    });

    testWidgets('Tapping search icon toggles search input bar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
        'Displays conversation item and persona filter tabs when active chat exists',
        (tester) async {
      await ChatService.instance.sendMessage(
        conversationId: 'user_clark',
        text: 'Up and away!',
        senderName: 'Clark Kent',
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Up and away!'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Clark Kent'), findsWidgets);
    });

    testWidgets('Tapping persona filter chip filters conversation list',
        (tester) async {
      await ChatService.instance.sendMessage(
        conversationId: 'user_clark',
        text: 'Up and away!',
        senderName: 'Clark Kent',
      );
      await ChatService.instance.sendMessage(
        conversationId: 'ai_persona_athena',
        text: 'Architecture approved',
        senderName: 'Athena',
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Before tapping, both conversations are visible
      expect(find.text('Up and away!'), findsOneWidget);

      // Tap 'Athena' chip
      await tester.tap(find.text('Athena').first);
      await tester.pumpAndSettle();

      // Only the Athena conversation is shown; Clark Kent's message is hidden (only his chip remains)
      expect(find.text('Up and away!'), findsNothing);
      expect(find.text('Clark Kent'), findsOneWidget); // only the chip

      // Tap 'All' chip
      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();

      // Both conversations are visible again
      expect(find.text('Up and away!'), findsOneWidget);
      expect(find.text('Clark Kent'), findsNWidgets(2)); // chip + message item
    });
  });
}
