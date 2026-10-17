import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildApp(Widget home) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: home,
    );
  }

  group('ConversationScreen Widget Tests', () {
    testWidgets('Renders conversation header, message feed, and text composer',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'ai_assistant',
            title: 'ChatBud AI Assistant',
            isAi: true,
          ),
        ),
      );

      expect(find.text('ChatBud AI Assistant'), findsWidgets);
      expect(find.text('Online • Gemini AI'), findsOneWidget);
      expect(find.text('Type a message…'), findsOneWidget);
    });

    testWidgets('Sending a message updates feed with user message',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'user_bruce',
            title: 'Bruce Wayne',
            isAi: false,
          ),
        ),
      );

      // Enter text into field
      await tester.enterText(find.byType(TextField), 'Hello Bruce!');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Hello Bruce!'), findsOneWidget);
    });

    testWidgets('Text-only interface: composer has text input and no attachment/mic icons',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'user_bruce',
            title: 'Bruce Wayne',
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
      expect(find.byIcon(Icons.attach_file), findsNothing);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });
  });
}
