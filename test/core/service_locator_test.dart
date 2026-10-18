import 'package:chatbud/src/core/app_state.dart';
import 'package:chatbud/src/core/service_locator.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/services/gemini_service.dart';
import 'package:chatbud/src/services/memory_service.dart';
import 'package:chatbud/src/services/persona_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceLocator', () {
    test('service<T>() self-initializes without an explicit setup call', () {
      // Intentionally do NOT call setupLocator() first.
      expect(service<ChatService>(), isNotNull);
    });

    test(
        'resolves the same singleton instances as the legacy .instance getters',
        () {
      setupLocator();
      expect(identical(service<ChatService>(), ChatService.instance), isTrue);
      expect(
          identical(service<MemoryService>(), MemoryService.instance), isTrue);
      expect(identical(service<PersonaService>(), PersonaService.instance),
          isTrue);
      expect(
          identical(service<GeminiService>(), GeminiService.instance), isTrue);
      expect(identical(service<AppState>(), AppState.instance), isTrue);
    });

    test('setupLocator is idempotent (safe to call repeatedly)', () {
      setupLocator();
      setupLocator();
      expect(service<MemoryService>(), isNotNull);
    });
  });
}
