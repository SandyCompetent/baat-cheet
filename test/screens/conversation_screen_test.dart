import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
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
        'Suggested prompts are hidden once the chat has started (no bottom suggestion chips)',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: 'ai_persona_aria',
            title: 'Aria',
            isAi: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      const starterPrompt =
          '✉️ Polish this draft email to leadership requesting budget';

      // Before sending a message, starter prompt is visible in empty state
      expect(find.text(starterPrompt), findsOneWidget);

      // Send initial message
      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      // After chat starts, starter prompts and bottom suggestion chips are hidden
      expect(find.text(starterPrompt), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets(
        'Disables send button and shows loading indicator while AI message is generating',
        (tester) async {
      const convId = 'ai_assistant_test_generating';
      await tester.pumpWidget(
        buildApp(
          const ConversationScreen(
            conversationId: convId,
            title: 'AI Assistant',
            isAi: true,
          ),
        ),
      );

      // Simulate active AI generation for this conversation
      ChatService.instance.generatingConversationsNotifier.value = {convId};
      await tester.pump();

      // Send arrow icon is replaced with loading indicator
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
      expect(
        find.byKey(const ValueKey('send_loading_indicator')),
        findsOneWidget,
      );

      // Attempting to type and tap the loading send button does not send a message
      await tester.enterText(find.byType(TextField), 'Blocked while loading');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('send_loading_indicator')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(
        ChatService.instance.getMessagesNotifier(convId).value,
        isEmpty,
      );

      // Once generation completes, send arrow icon is restored
      ChatService.instance.generatingConversationsNotifier.value = {};
      await tester.pump();
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });
}
