import 'package:chatbud/src/services/gemini_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiService (Firebase AI Logic) Tests', () {
    test('Singleton instance initializes without crashing', () {
      final service = GeminiService.instance;
      expect(service, isNotNull);
    });

    test('streamResponse emits fallback tokens when Firebase backend is uninitialized in test environment', () async {
      final service = GeminiService.instance;
      final tokens = <String>[];

      await for (final token in service.streamResponse(prompt: 'Hello')) {
        tokens.add(token);
      }

      expect(tokens.isNotEmpty, isTrue);
      final fullResponse = tokens.join();
      expect(fullResponse.toLowerCase().contains('chatbud ai'), isTrue);
    });

    test('streamResponse handles conversation history properly', () async {
      final service = GeminiService.instance;
      final history = [
        ChatMessage(
          id: '1',
          text: 'Hi there',
          isUser: true,
          senderName: 'User',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          text: 'Hello, how can I help?',
          isUser: false,
          senderName: 'ChatBud AI',
          timestamp: DateTime.now(),
        ),
      ];

      final tokens = <String>[];
      await for (final token in service.streamResponse(prompt: 'Tell me about the slate theme', history: history)) {
        tokens.add(token);
      }

      expect(tokens.isNotEmpty, isTrue);
      final combined = tokens.join();
      expect(combined.toLowerCase().contains('slate'), isTrue);
    });

    test('currentModel defaults to gemini-3.1-flash-lite and setModel switches model', () {
      final service = GeminiService.instance;
      expect(service.currentModel, GeminiService.modelFlashLite);

      service.setModel(GeminiService.modelFlash);
      expect(service.currentModel, GeminiService.modelFlash);

      // Reset back to flash-lite
      service.setModel(GeminiService.modelFlashLite);
      expect(service.currentModel, GeminiService.modelFlashLite);
    });

    test('streamResponse accepts systemInstruction and modelOverride', () async {
      final service = GeminiService.instance;
      final tokens = <String>[];

      await for (final token in service.streamResponse(
        prompt: 'Who are you?',
        systemInstruction: 'You are Athena, system architect.',
        modelOverride: GeminiService.modelFlashLite,
      )) {
        tokens.add(token);
      }

      expect(tokens.isNotEmpty, isTrue);
    });
  });
}
