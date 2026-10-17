import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/secure_storage_service.dart';
import '../models/chat_message.dart';

/// Gemini AI Service powering ChatBud AI Assistant with real-time text streaming.
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  static const String _defaultEnvKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  GenerativeModel? _model;
  String? _cachedKey;

  Future<GenerativeModel?> _getModel() async {
    final storedKey = await SecureStorageService.getGeminiApiKey();
    final effectiveKey =
        (storedKey != null && storedKey.isNotEmpty) ? storedKey : _defaultEnvKey;

    if (effectiveKey.isEmpty) return null;

    if (_model == null || _cachedKey != effectiveKey) {
      _cachedKey = effectiveKey;
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: effectiveKey,
        systemInstruction: Content.system(
          'You are ChatBud AI, a helpful, intelligent, and concise assistant built into the ChatBud workspace. '
          'Provide clear, actionable, friendly, and well-formatted answers.',
        ),
      );
    }
    return _model;
  }

  /// Streams token-by-token chunks from Gemini API
  Stream<String> streamResponse({
    required String prompt,
    List<ChatMessage> history = const [],
  }) async* {
    final model = await _getModel();

    if (model == null) {
      // Graceful offline/demo response when no API key is configured yet
      yield* _streamFallbackResponse(prompt);
      return;
    }

    try {
      final contents = <Content>[];

      // Convert recent history (up to last 6 messages) into Gemini Content
      final recent = history.length > 6
          ? history.sublist(history.length - 6)
          : history;
      for (final m in recent) {
        if (m.isUser) {
          contents.add(Content.text(m.text));
        } else {
          contents.add(Content.model([TextPart(m.text)]));
        }
      }

      contents.add(Content.text(prompt));

      final responseStream = model.generateContentStream(contents);
      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      yield '\n[AI response error: ${e.toString()}]. Please check your network or Gemini API Key.';
    }
  }

  Stream<String> _streamFallbackResponse(String prompt) async* {
    final lower = prompt.toLowerCase();
    String reply;

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      reply =
          'Hello! I am ChatBud AI Assistant. I am ready to help you summarize ideas, draft messages, and answer questions.';
    } else if (lower.contains('theme') || lower.contains('slate')) {
      reply =
          'The Soft Minimalist Slate theme uses cool neutral tones (#F8FAFC canvas, #FFFFFF surface, #111827 dark mode) with Electric Indigo accents for optimal legibility and zero glare.';
    } else if (lower.contains('help') || lower.contains('api key')) {
      reply =
          'To connect me to live Gemini AI responses, you can configure your Gemini API Key in Profile -> Settings -> AI Configuration.';
    } else {
      reply =
          'I received your message: "$prompt". Connect your free Gemini API Key in Settings to unlock real-time streaming intelligence!';
    }

    // Simulate natural token typing in small chunks
    final words = reply.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }
}
