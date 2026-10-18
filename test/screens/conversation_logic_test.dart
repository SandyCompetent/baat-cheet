import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/screen/conversation/conversation_suggestions.dart';
import 'package:chatbud/src/screen/conversation/transcript_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage _msg(String text, {required bool isUser}) => ChatMessage(
      id: 'm_${text.hashCode}',
      text: text,
      isUser: isUser,
      senderName: isUser ? 'You' : 'ChatBud AI',
      timestamp: DateTime(2026, 1, 1),
    );

void main() {
  group('ConversationSuggestions', () {
    const starters = ['Say hello 👋', 'Help me', 'What can you do?'];

    test('falls back to starter prompts when there is no history', () {
      final result = ConversationSuggestions.forHistory(
        messages: const [],
        starterPrompts: starters,
      );
      expect(result, starters);
    });

    test('falls back to starters when last message is from the user', () {
      final result = ConversationSuggestions.forHistory(
        messages: [_msg('hi', isUser: true)],
        starterPrompts: starters,
      );
      expect(result, starters);
    });

    test('returns code replies when the AI talked about code/flutter', () {
      final result = ConversationSuggestions.forHistory(
        messages: [_msg('Here is a Flutter function for you', isUser: false)],
        starterPrompts: starters,
      );
      expect(result, ConversationSuggestions.codeReplies);
    });

    test('returns guide replies for step/how-to content', () {
      final result = ConversationSuggestions.forHistory(
        messages: [_msg('Step 1: do this, step 2: do that', isUser: false)],
        starterPrompts: starters,
      );
      expect(result, ConversationSuggestions.guideReplies);
    });

    test('returns question replies when the AI asked something', () {
      final result = ConversationSuggestions.forHistory(
        messages: [_msg('Would you like me to continue?', isUser: false)],
        starterPrompts: starters,
      );
      expect(result, ConversationSuggestions.questionReplies);
    });

    test('returns generic replies otherwise', () {
      final result = ConversationSuggestions.forHistory(
        messages: [_msg('The weather is pleasant today.', isUser: false)],
        starterPrompts: starters,
      );
      expect(result, ConversationSuggestions.genericReplies);
    });
  });

  group('TranscriptExporter', () {
    final messages = [
      _msg('Hello there', isUser: true),
      _msg('Hi! How can I help?', isUser: false),
    ];

    test('plain text transcript includes sender labels and content', () {
      final out = TranscriptExporter.build(
        messages: messages,
        title: 'Aria',
        asMarkdown: false,
        now: DateTime(2026, 2, 3),
      );
      expect(out.contains('ChatBud Transcript with Aria (2026-02-03)'), isTrue);
      expect(out.contains('[You]: Hello there'), isTrue);
      expect(out.contains('[Aria]: Hi! How can I help?'), isTrue);
    });

    test('markdown transcript uses headings', () {
      final out = TranscriptExporter.build(
        messages: messages,
        title: 'Aria',
        asMarkdown: true,
        now: DateTime(2026, 2, 3),
      );
      expect(out.contains('# ChatBud Transcript — Aria'), isTrue);
      expect(out.contains('### You'), isTrue);
      expect(out.contains('### Aria'), isTrue);
    });

    test('empty history yields a header-only transcript', () {
      final out = TranscriptExporter.build(
        messages: const [],
        title: 'Aria',
        asMarkdown: false,
        now: DateTime(2026, 2, 3),
      );
      expect(out.contains('ChatBud Transcript with Aria'), isTrue);
      expect(out.contains('[You]'), isFalse);
    });
  });
}
