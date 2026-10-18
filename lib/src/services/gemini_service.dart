import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/chat_message.dart';
import '../core/app_logger.dart';

/// Production AI Service powered by the Firebase AI SDK (`firebase_ai`).
/// Connects to the Gemini Developer API with a 100% free serverless tier.
/// Follows official Google documentation on model retirement:
/// Uses modern Gemini 3.x models (`gemini-3.1-flash-lite` by default, `gemini-3.8-flash`)
/// and prevents 404 errors by supporting dynamic model reconfiguration.
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  /// Default fast, lightweight free-tier model recommended for use
  static const String defaultModel = 'gemini-3.1-flash-lite';
  static const String proModel = 'gemini-3.8-flash';
  static const String modelFlashLite = defaultModel;
  static const String modelFlash = proModel;

  String _currentModel = defaultModel;
  String get currentModel => _currentModel;

  void setModel(String model) {
    if (model.trim().isNotEmpty && model != _currentModel) {
      _currentModel = model.trim();
      _cachedModel = null;
    }
  }

  GenerativeModel? _cachedModel;
  String? _cachedSystemInstruction;
  String? _cachedModelName;

  static const String defaultSystemInstruction =
      'You are ChatBud AI, an intelligent, helpful, and concise assistant built into the ChatBud workspace. '
      'Provide clear, actionable, friendly, and well-formatted answers.';

  GenerativeModel? _getModel({String? systemInstruction, String? modelOverride}) {
    final targetModel = modelOverride ?? _currentModel;
    final targetInstruction = systemInstruction ?? defaultSystemInstruction;

    if (_cachedModel != null &&
        _cachedModelName == targetModel &&
        _cachedSystemInstruction == targetInstruction) {
      return _cachedModel;
    }

    try {
      final googleAI = FirebaseAI.googleAI();
      _cachedModel = googleAI.generativeModel(
        model: targetModel,
        systemInstruction: Content.system(targetInstruction),
      );
      _cachedModelName = targetModel;
      _cachedSystemInstruction = targetInstruction;
      return _cachedModel;
    } catch (e, st) {
      AppLogger.e(
        'Failed to initialize Firebase AI model "$targetModel"',
        tag: 'GeminiService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Streams token-by-token chunks using Firebase AI SDK
  Stream<String> streamResponse({
    required String prompt,
    List<ChatMessage> history = const [],
    String? systemInstruction,
    String? modelOverride,
  }) async* {
    final model = _getModel(
      systemInstruction: systemInstruction,
      modelOverride: modelOverride,
    );

    if (model == null) {
      AppLogger.w(
        'Firebase AI model unavailable — serving canned fallback response. '
        'The LLM is NOT being called. Check Firebase AI provisioning / model id.',
        tag: 'GeminiService',
      );
      yield* _streamFallbackResponse(prompt);
      return;
    }

    bool hasEmitted = false;
    try {
      final contents = <Content>[];

      // Convert recent history (up to last 6 messages) into Content
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
          hasEmitted = true;
          yield text;
        }
      }
    } catch (e) {
      if (!hasEmitted) {
        AppLogger.e(
          'Firebase AI stream failed before emitting any tokens — '
          'falling back to canned response.',
          tag: 'GeminiService',
          error: e,
        );
        // Graceful fallback if Firebase AI is not yet provisioned in Firebase console or offline
        yield* _streamFallbackResponse(prompt);
      } else {
        AppLogger.w(
          'Firebase AI stream interrupted after partial output.',
          tag: 'GeminiService',
          error: e,
        );
        yield '\n\n[Response paused. Please check your connection.]';
      }
    }
  }

  Stream<String> _streamFallbackResponse(String prompt) async* {
    final lower = prompt.toLowerCase();
    String reply;

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      reply =
          'Hello! I am ChatBud AI Assistant. How can I help you today?';
    } else if (lower.contains('theme') || lower.contains('slate')) {
      reply =
          'The Soft Minimalist Slate theme uses cool slate-tinted neutrals (#F8FAFC canvas, #FFFFFF surface, #111827 dark mode) with high-contrast electric indigo accents.';
    } else if (lower.contains('firebase') || lower.contains('free') || lower.contains('ai') || lower.contains('model')) {
      reply =
          'ChatBud runs on AI Assistant ($defaultModel).';
    } else {
      reply =
          'I am ChatBud AI Assistant. I received your message: "$prompt". What would you like to explore or discuss next?';
    }

    // Simulate token streaming
    final words = reply.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }
}
