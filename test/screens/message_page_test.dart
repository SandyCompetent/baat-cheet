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
    testWidgets('Renders app title, filter chips, and AI assistant onboarding button when empty',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('No conversations found'), findsOneWidget);
      expect(find.text('Chat with AI Assistant'), findsOneWidget);
    });

    testWidgets('Tapping search icon toggles search input bar', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Displays conversation item when active chat exists',
        (tester) async {
      await ChatService.instance.sendMessage(
        conversationId: 'user_clark',
        text: 'Up and away!',
        senderName: 'Clark Kent',
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Up and away!'), findsOneWidget);
    });
  });
}
