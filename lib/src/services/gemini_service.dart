import 'dart:async';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart' as fb_ai;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google_ai;
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../core/app_logger.dart';
import '../core/storage_service.dart';

/// Production AI Service supporting a Hybrid Live Architecture:
/// 1. Default Zero-Config Mode: Powered by the Firebase AI SDK (`firebase_ai`),
///    connecting to the Gemini Developer API with a 100% free serverless tier.
/// 2. Bring Your Own API Key (BYOK) Mode: Powered by `google_generative_ai` when
///    the user provides a custom Gemini API key in Settings or via
///    `--dart-define=API_KEY=...` at build time, including live model discovery.
class GeminiService extends ChangeNotifier {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  /// Build-time optional API key (--dart-define=API_KEY=your_key_here)
  static const String defaultEnvApiKey =
      String.fromEnvironment('API_KEY', defaultValue: '');

  /// Default fast, lightweight free-tier model recommended for use
  static const String defaultModel = 'gemini-3.1-flash-lite';
  static const String proModel = 'gemini-3.8-flash';
  static const String modelFlashLite = defaultModel;
  static const String modelFlash = proModel;

  /// Curated modern Gemini models always available in the selector
  static const List<String> builtInModels = [
    defaultModel,
    proModel,
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.5-flash-lite',
  ];

  String _apiKey = defaultEnvApiKey;
  String _currentModel = defaultModel;
  List<String> _availableModels = List<String>.from(builtInModels);
  bool _isLoadingModels = false;
  String? _modelError;

  String get apiKey => _apiKey;
  bool get hasCustomApiKey => _apiKey.trim().isNotEmpty;
  String get currentModel => _currentModel;
  List<String> get availableModels => List.unmodifiable(_availableModels);
  bool get isLoadingModels => _isLoadingModels;
  String? get modelError => _modelError;

  fb_ai.GenerativeModel? _cachedFirebaseModel;
  google_ai.GenerativeModel? _cachedByokModel;
  String? _cachedSystemInstruction;
  String? _cachedModelName;
  String? _cachedApiKey;

  static const String defaultSystemInstruction =
      'You are ChatBud AI, an intelligent, helpful, and concise assistant built into the ChatBud workspace. '
      'Provide clear, actionable, friendly, and well-formatted answers.';

  /// Restores persisted BYOK API key, selected model, and cached model list.
  void loadFromStorage() {
    final storedKey = StorageService.getCustomApiKey();
    if (storedKey != null && storedKey.trim().isNotEmpty) {
      _apiKey = storedKey.trim();
    } else {
      _apiKey = defaultEnvApiKey;
    }

    final storedModels = StorageService.getAvailableModels();
    if (storedModels.isNotEmpty) {
      final merged = <String>[...storedModels];
      for (final m in builtInModels) {
        if (!merged.contains(m)) merged.add(m);
      }
      _availableModels = merged;
    } else {
      _availableModels = List<String>.from(builtInModels);
    }

    final storedSelected = StorageService.getSelectedModel();
    if (storedSelected != null && storedSelected.trim().isNotEmpty) {
      _currentModel = storedSelected.trim();
      if (!_availableModels.contains(_currentModel)) {
        _availableModels = [_currentModel, ..._availableModels];
      }
    }

    _invalidateCache();
    notifyListeners();
  }

  void _invalidateCache() {
    _cachedFirebaseModel = null;
    _cachedByokModel = null;
    _cachedSystemInstruction = null;
    _cachedModelName = null;
    _cachedApiKey = null;
  }

  /// Sets or clears the user's custom Gemini API key (BYOK).
  /// Passing an empty string reverts to the default live Firebase AI backend.
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    _apiKey = trimmed;
    _modelError = null;
    _invalidateCache();

    if (trimmed.isEmpty) {
      _availableModels = List<String>.from(builtInModels);
      if (!_availableModels.contains(_currentModel)) {
        _currentModel = defaultModel;
        await StorageService.setSelectedModel(_currentModel);
      }
      await StorageService.setAvailableModels(_availableModels);
    }

    await StorageService.setCustomApiKey(trimmed);
    notifyListeners();
  }

  /// Switches the active Gemini model.
  void setModel(String model) {
    final trimmed = model.trim();
    if (trimmed.isNotEmpty && trimmed != _currentModel) {
      _currentModel = trimmed;
      if (!_availableModels.contains(_currentModel)) {
        _availableModels = [..._availableModels, _currentModel];
      }
      _invalidateCache();
      StorageService.setSelectedModel(_currentModel);
      notifyListeners();
    }
  }

  /// Dynamically queries the Gemini Developer API for text-capable models
  /// available to the configured API key.
  Future<void> fetchAvailableModels({http.Client? httpClient}) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      _modelError =
          'Please enter a Gemini API Key first to fetch custom models.';
      notifyListeners();
      return;
    }

    _isLoadingModels = true;
    _modelError = null;
    notifyListeners();

    final client = httpClient ?? http.Client();
    try {
      final response = await client.get(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = (data['models'] as List<dynamic>?) ?? [];

        final validModels = models
            .where((m) {
              final map = m as Map<String, dynamic>;
              final methods = map['supportedGenerationMethods'] as List?;
              final name = (map['name'] as String? ?? '').toLowerCase();
              final displayName =
                  (map['displayName'] as String? ?? '').toLowerCase();
              final description =
                  (map['description'] as String? ?? '').toLowerCase();

              // 1. Must support text generation
              final isContentGeneration =
                  methods != null && methods.contains('generateContent');

              // 2. Filter out models explicitly for audio, image, or vision tasks
              final isAudioOrImageOrVision = name.contains('vision') ||
                  name.contains('audio') ||
                  name.contains('image') ||
                  displayName.contains('vision') ||
                  displayName.contains('audio') ||
                  displayName.contains('image') ||
                  description.contains('audio only') ||
                  description.contains('image only');

              // 3. Filter out deprecated or legacy models
              final isDeprecated = description.contains('deprecated') ||
                  displayName.contains('deprecated') ||
                  description.contains('legacy') ||
                  name.contains('gemini-1.0');

              return isContentGeneration &&
                  !isAudioOrImageOrVision &&
                  !isDeprecated;
            })
            .map((m) => ((m as Map<String, dynamic>)['name'] as String)
                .replaceFirst('models/', ''))
            .toList();

        if (validModels.isNotEmpty) {
          final merged = <String>[...validModels];
          for (final b in builtInModels) {
            if (!merged.contains(b)) merged.add(b);
          }
          _availableModels = merged;
          await StorageService.setAvailableModels(_availableModels);

          if (!_availableModels.contains(_currentModel)) {
            if (validModels.contains('gemini-2.5-flash')) {
              _currentModel = 'gemini-2.5-flash';
            } else if (validModels.contains(defaultModel)) {
              _currentModel = defaultModel;
            } else {
              _currentModel = validModels.first;
            }
            await StorageService.setSelectedModel(_currentModel);
          }
        } else {
          _modelError = 'No valid text models found for this API key.';
        }
      } else {
        _modelError = 'Failed to fetch models: HTTP ${response.statusCode}';
      }
    } catch (e) {
      _modelError = 'Error fetching models: $e';
    } finally {
      if (httpClient == null) {
        client.close();
      }
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  fb_ai.GenerativeModel? _getFirebaseModel({
    String? systemInstruction,
    String? modelOverride,
  }) {
    final targetModel = modelOverride ?? _currentModel;
    final targetInstruction = systemInstruction ?? defaultSystemInstruction;

    if (_cachedFirebaseModel != null &&
        _cachedModelName == targetModel &&
        _cachedSystemInstruction == targetInstruction) {
      return _cachedFirebaseModel;
    }

    try {
      final googleAI = fb_ai.FirebaseAI.googleAI();
      _cachedFirebaseModel = googleAI.generativeModel(
        model: targetModel,
        systemInstruction: fb_ai.Content.system(targetInstruction),
      );
      _cachedModelName = targetModel;
      _cachedSystemInstruction = targetInstruction;
      return _cachedFirebaseModel;
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

  google_ai.GenerativeModel _getByokModel({
    required String apiKey,
    String? systemInstruction,
    String? modelOverride,
  }) {
    final targetModel = modelOverride ?? _currentModel;
    final targetInstruction = systemInstruction ?? defaultSystemInstruction;

    if (_cachedByokModel != null &&
        _cachedApiKey == apiKey &&
        _cachedModelName == targetModel &&
        _cachedSystemInstruction == targetInstruction) {
      return _cachedByokModel!;
    }

    _cachedByokModel = google_ai.GenerativeModel(
      model: targetModel,
      apiKey: apiKey,
      systemInstruction: google_ai.Content.system(targetInstruction),
    );
    _cachedApiKey = apiKey;
    _cachedModelName = targetModel;
    _cachedSystemInstruction = targetInstruction;
    return _cachedByokModel!;
  }

  /// Streams token-by-token chunks using either the user's BYOK Gemini API key
  /// (`google_generative_ai`) or the default live Firebase AI SDK (`firebase_ai`).
  Stream<String> streamResponse({
    required String prompt,
    List<ChatMessage> history = const [],
    String? systemInstruction,
    String? modelOverride,
  }) async* {
    if (hasCustomApiKey) {
      yield* _streamByokResponse(
        apiKey: _apiKey.trim(),
        prompt: prompt,
        history: history,
        systemInstruction: systemInstruction,
        modelOverride: modelOverride,
      );
      return;
    }

    final model = _getFirebaseModel(
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
      final contents = <fb_ai.Content>[];

      // Convert recent history (up to last 6 messages) into Content
      final recent =
          history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final m in recent) {
        if (m.text.trim().isEmpty) continue;
        if (m.isUser) {
          contents.add(fb_ai.Content.text(m.text));
        } else {
          contents.add(fb_ai.Content.model([fb_ai.TextPart(m.text)]));
        }
      }

      contents.add(fb_ai.Content.text(prompt));

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

  Stream<String> _streamByokResponse({
    required String apiKey,
    required String prompt,
    required List<ChatMessage> history,
    String? systemInstruction,
    String? modelOverride,
  }) async* {
    final model = _getByokModel(
      apiKey: apiKey,
      systemInstruction: systemInstruction,
      modelOverride: modelOverride,
    );

    try {
      final contents = <google_ai.Content>[];
      final recent =
          history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final m in recent) {
        if (m.text.trim().isEmpty) continue;
        if (m.isUser) {
          contents.add(google_ai.Content.text(m.text));
        } else {
          contents.add(google_ai.Content.model([google_ai.TextPart(m.text)]));
        }
      }
      contents.add(google_ai.Content.text(prompt));

      final responseStream = model.generateContentStream(contents);
      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } on google_ai.InvalidApiKey catch (_) {
      yield 'Error: Invalid API Key. Please check your configuration in Profile Settings, or clear the key to use Default Firebase AI.';
    } on google_ai.UnsupportedUserLocation catch (_) {
      yield 'Error: Gemini API is not supported in your location.';
    } catch (e) {
      AppLogger.e(
        'BYOK Gemini stream error',
        tag: 'GeminiService',
        error: e,
      );
      yield 'Error: $e';
    }
  }

  /// Generates 3 contextual follow-up questions based on the last assistant
  /// response (ported from Exeter Academic Agent). Returns an empty list on error
  /// so the caller can fall back to heuristic suggestions.
  Future<List<String>> generateSuggestions(String lastAssistantResponse) async {
    if (lastAssistantResponse.trim().isEmpty) return [];

    final prompt = '''
Based on the following explanation an AI assistant just gave:
"$lastAssistantResponse"

Provide exactly 3 short, relevant follow-up questions the user might want to ask next.
Format the output as a strict JSON array of strings, e.g. ["Question 1?", "Question 2?", "Question 3?"].
Do not include any markdown formatting like ```json or any other text. Just the array.
''';

    try {
      String rawText = '';
      if (hasCustomApiKey) {
        final suggestionModel = google_ai.GenerativeModel(
          model: 'gemini-2.5-flash-lite',
          apiKey: _apiKey.trim(),
        );
        final response = await suggestionModel.generateContent([
          google_ai.Content.text(prompt),
        ]);
        rawText = response.text?.trim() ?? '[]';
      } else {
        final fbModel = _getFirebaseModel(modelOverride: defaultModel);
        if (fbModel == null) return [];
        final response = await fbModel.generateContent([
          fb_ai.Content.text(prompt),
        ]);
        rawText = response.text?.trim() ?? '[]';
      }

      final cleanText =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanText);
      return decoded.map((e) => e.toString()).take(3).toList();
    } catch (_) {
      return [];
    }
  }

  Stream<String> _streamFallbackResponse(String prompt) async* {
    final lower = prompt.toLowerCase();
    String reply;

    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      reply = 'Hello! I am ChatBud AI Assistant. How can I help you today?';
    } else if (lower.contains('theme') || lower.contains('slate')) {
      reply =
          'The Soft Minimalist Slate theme uses cool slate-tinted neutrals (#F8FAFC canvas, #FFFFFF surface, #111827 dark mode) with high-contrast electric indigo accents.';
    } else if (lower.contains('firebase') ||
        lower.contains('free') ||
        lower.contains('ai') ||
        lower.contains('model')) {
      reply = 'ChatBud runs on AI Assistant ($defaultModel).';
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
