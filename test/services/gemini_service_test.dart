import 'dart:convert';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/services/gemini_service.dart';
import 'package:chatbud/src/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    await GeminiService.instance.setApiKey('');
    GeminiService.instance.setModel(GeminiService.modelFlashLite);
  });

  group('GeminiService Tests', () {
    test('Singleton instance initializes without crashing', () {
      final service = GeminiService.instance;
      expect(service, isNotNull);
      expect(service.hasCustomApiKey, isFalse);
    });

    test(
        'streamResponse emits fallback tokens when Firebase backend is uninitialized in test environment',
        () async {
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
      await for (final token in service.streamResponse(
          prompt: 'Tell me about the slate theme', history: history)) {
        tokens.add(token);
      }

      expect(tokens.isNotEmpty, isTrue);
      final combined = tokens.join();
      expect(combined.toLowerCase().contains('slate'), isTrue);
    });

    test(
        'currentModel defaults to gemini-3.1-flash-lite and setModel switches model',
        () {
      final service = GeminiService.instance;
      expect(service.currentModel, GeminiService.modelFlashLite);

      service.setModel(GeminiService.modelFlash);
      expect(service.currentModel, GeminiService.modelFlash);

      // Reset back to flash-lite
      service.setModel(GeminiService.modelFlashLite);
      expect(service.currentModel, GeminiService.modelFlashLite);
    });

    test('streamResponse accepts systemInstruction and modelOverride',
        () async {
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

    test('setApiKey toggles BYOK mode and persists to StorageService',
        () async {
      final service = GeminiService.instance;
      expect(service.hasCustomApiKey, isFalse);

      await service.setApiKey('AIzaSyTestKey123');
      expect(service.hasCustomApiKey, isTrue);
      expect(service.apiKey, 'AIzaSyTestKey123');
      expect(StorageService.getCustomApiKey(), 'AIzaSyTestKey123');

      await service.setApiKey('');
      expect(service.hasCustomApiKey, isFalse);
      expect(StorageService.getCustomApiKey(), isNull);
    });

    test('fetchAvailableModels sets modelError when API key is empty',
        () async {
      final service = GeminiService.instance;
      await service.setApiKey('');
      await service.fetchAvailableModels();

      expect(service.modelError, isNotNull);
      expect(service.modelError!.contains('API Key'), isTrue);
    });

    test(
        'fetchAvailableModels filters text-capable models and excludes deprecated/vision models',
        () async {
      final service = GeminiService.instance;
      await service.setApiKey('AIzaSyValidMockKey');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-2.5-flash',
                'displayName': 'Gemini 2.5 Flash',
                'description': 'Fast multimodal model',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-1.0-pro',
                'displayName': 'Gemini 1.0 Pro',
                'description': 'Legacy model',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-pro-vision',
                'displayName': 'Gemini Vision',
                'description': 'Vision model',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/text-embedding-004',
                'displayName': 'Text Embedding',
                'description': 'Embeddings',
                'supportedGenerationMethods': ['embedContent'],
              },
            ],
          }),
          200,
        );
      });

      await service.fetchAvailableModels(httpClient: mockClient);

      expect(service.modelError, isNull);
      expect(service.availableModels.contains('gemini-2.5-flash'), isTrue);
      expect(service.availableModels.contains('gemini-1.0-pro'), isFalse);
      expect(service.availableModels.contains('gemini-pro-vision'), isFalse);
      expect(service.availableModels.contains('text-embedding-004'), isFalse);
    });
  });
}
