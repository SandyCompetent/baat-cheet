import '../../models/chat_message.dart';

/// Pure transcript formatting extracted from `ConversationScreen` so it can be
/// unit-tested and reused without a widget tree. No Flutter / clipboard / UI
/// dependencies — just message-list → string.
class TranscriptExporter {
  const TranscriptExporter._();

  /// Build a shareable transcript of [messages] for a conversation titled
  /// [title]. When [asMarkdown] is true, emits Markdown headings; otherwise a
  /// clean plain-text log. [now] is injectable for deterministic tests.
  static String build({
    required List<ChatMessage> messages,
    required String title,
    required bool asMarkdown,
    DateTime? now,
  }) {
    final date = (now ?? DateTime.now()).toLocal().toString().split(' ').first;
    final buffer = StringBuffer();

    if (asMarkdown) {
      buffer.writeln('# ChatBud Transcript — $title');
      buffer.writeln('*Date: $date*\n');
      for (final m in messages) {
        final sender = m.isUser ? 'You' : title;
        buffer.writeln('### $sender');
        buffer.writeln('${m.text}\n');
      }
    } else {
      buffer.writeln('ChatBud Transcript with $title ($date)');
      buffer.writeln('=' * 40);
      for (final m in messages) {
        final sender = m.isUser ? 'You' : title;
        buffer.writeln('[$sender]: ${m.text}\n');
      }
    }

    return buffer.toString().trim();
  }
}
