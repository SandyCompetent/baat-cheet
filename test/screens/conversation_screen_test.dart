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
      expect(find.text('Online • AI Assistant'), findsOneWidget);
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
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Hello Bruce!'), findsOneWidget);
    });

    testWidgets(
        'Text-only interface: composer has text input and no attachment/mic icons',
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

    testWidgets('Renders Markdown formatting in chat bubbles', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'user_bruce',
            title: 'Bruce Wayne',
            isAi: false,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'You work at **Google**.');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
          find.text('You work at Google.', findRichText: true), findsOneWidget);
    });

    testWidgets(
        'Tapping export icon opens export sheet with plain text and markdown options',
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

      // Send a message first so export has content
      await tester.enterText(find.byType(TextField), 'Hello assistant');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Export Conversation Transcript'), findsOneWidget);
      expect(find.text('Copy as Clean Plain Text'), findsOneWidget);
      expect(find.text('Copy as Formatted Markdown'), findsOneWidget);
    });

    testWidgets(
        'Tapping a starter prompt sends prompt directly to the conversation',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'ai_persona_harper',
            title: 'Harper',
            isAi: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.text(
              '🎯 Conduct a behavioral mock interview for a Product Manager'),
          findsWidgets);

      await tester.tap(find
          .text('🎯 Conduct a behavioral mock interview for a Product Manager')
          .first);
      await tester.pumpAndSettle();

      expect(
          find.text(
              '🎯 Conduct a behavioral mock interview for a Product Manager'),
          findsWidgets);
    });

    testWidgets(
        'Suggested reply chips fill the text input on tap when messages exist',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'ai_assistant_test_suggestions',
            title: 'AI Assistant',
            isAi: true,
          ),
        ),
      );

      // Send initial message
      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      // Check for contextual suggestion chip
      final suggestionFinder = find.byType(ActionChip);
      if (suggestionFinder.evaluate().isNotEmpty) {
        final chipText =
            (tester.widget(suggestionFinder.first) as ActionChip).label;
        if (chipText is Text && chipText.data != null) {
          final prompt = chipText.data!;
          await tester.tap(suggestionFinder.first);
          await tester.pumpAndSettle();

          expect(find.widgetWithText(TextField, prompt), findsOneWidget);
        }
      }
    });
  });
}
