import '../../models/chat_message.dart';

/// Context-aware suggested-reply engine extracted from `ConversationScreen`.
///
/// Pure logic (message history → suggestion chips) with no widget dependencies,
/// so the heuristic is unit-testable in isolation and the screen file shrinks.
class ConversationSuggestions {
  const ConversationSuggestions._();

  static const List<String> codeReplies = [
    'Can you add comments to this code?',
    'How do I test this function?',
    'Explain this step-by-step',
  ];

  static const List<String> guideReplies = [
    'Give me a concrete example',
    'What are the common pitfalls?',
    'Summarize key takeaways',
  ];

  static const List<String> questionReplies = [
    'Yes, please tell me more!',
    "Let's try another approach",
    'Can you clarify that last part?',
  ];

  static const List<String> genericReplies = [
    'Can you elaborate on that?',
    'Give me a practical example',
    'Summarize in 3 bullet points',
  ];

  /// Returns the suggestions to show below the composer given the current
  /// [messages]. Falls back to [starterPrompts] when there is no assistant
  /// message to react to.
  static List<String> forHistory({
    required List<ChatMessage> messages,
    required List<String> starterPrompts,
  }) {
    if (messages.isNotEmpty) {
      final lastMsg = messages.last;
      if (!lastMsg.isUser && lastMsg.text.isNotEmpty) {
        final textLower = lastMsg.text.toLowerCase();
        if (textLower.contains('code') ||
            textLower.contains('function') ||
            textLower.contains('class') ||
            textLower.contains('flutter') ||
            textLower.contains('dart')) {
          return codeReplies;
        } else if (textLower.contains('step') ||
            textLower.contains('how to') ||
            textLower.contains('guide')) {
          return guideReplies;
        } else if (textLower.contains('?') ||
            textLower.contains('would you like')) {
          return questionReplies;
        } else {
          return genericReplies;
        }
      }
    }
    return starterPrompts;
  }
}
