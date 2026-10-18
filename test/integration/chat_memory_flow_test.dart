import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/services/memory_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end flow: a user message to the AI assistant should (1) be stored,
/// (2) trigger an AI/persona response in the thread, and (3) extract a
/// long-term memory when the message contains a preference signal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  test(
      'sendMessage to AI assistant stores message, replies, and extracts memory',
      () async {
    final chat = ChatService.instance;
    final memory = MemoryService.instance;

    const conversationId = 'ai_assistant';
    const text =
        'I prefer concise, bullet-point answers when you explain things.';

    final sent = await chat.sendMessage(
      conversationId: conversationId,
      text: text,
      senderName: 'Guest User',
    );

    expect(sent.isUser, isTrue);

    final notifier = chat.getMessagesNotifier(conversationId);
    expect(notifier.value.any((m) => m.id == sent.id), isTrue);

    // The persona placeholder/response message is added to the thread.
    expect(notifier.value.any((m) => !m.isUser), isTrue);

    // Memory extraction is fire-and-forget; give it a moment to persist.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final extracted = memory.memoriesNotifier.value
        .any((m) => m.fact.toLowerCase().contains('bullet-point'));
    expect(extracted, isTrue,
        reason: 'a preference ("I prefer ...") should become a memory');
  });
}
