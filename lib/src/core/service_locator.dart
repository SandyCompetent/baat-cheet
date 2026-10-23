import 'package:get_it/get_it.dart';
import '../services/chat_service.dart';
import '../services/gemini_service.dart';
import '../services/group_service.dart';
import '../services/memory_service.dart';
import '../services/persona_service.dart';
import '../services/public_api_rag_service.dart';
import 'app_state.dart';

/// Service locator / dependency-injection composition root for ChatBud.
///
/// ## Why this exists
/// The app's services were historically hard singletons accessed as
/// `X.instance` directly from widgets, which couples every screen to a concrete
/// implementation and makes fakes awkward to inject. This locator introduces a
/// single composition root so call sites depend on a *lookup* (`service<T>()`)
/// rather than a concrete class, which is the seam needed for testing and for
/// swapping implementations later.
///
/// ## Migration strategy (intentionally non-breaking)
/// Each service is registered as a lazy singleton that returns the existing
/// `.instance`, so `service<T>()` and `X.instance` resolve to the *same* object.
/// This lets call sites migrate incrementally without changing behavior, and
/// keeps the existing test-suite (which uses `.instance`) green. The follow-up
/// is to convert the services to constructor-injected dependencies and register
/// real factories here instead of delegating to `.instance`.
final GetIt locator = GetIt.instance;

/// Registers all services. Idempotent: safe to call multiple times (e.g. from
/// `main()` and again lazily from [service] inside a widget test).
void setupLocator() {
  if (locator.isRegistered<AppState>()) return;

  locator.registerLazySingleton<AppState>(() => AppState.instance);
  locator.registerLazySingleton<ChatService>(() => ChatService.instance);
  locator.registerLazySingleton<MemoryService>(() => MemoryService.instance);
  locator.registerLazySingleton<PersonaService>(() => PersonaService.instance);
  locator.registerLazySingleton<GeminiService>(() => GeminiService.instance);
  locator.registerLazySingleton<GroupService>(() => GroupService.instance);
  locator.registerLazySingleton<PublicApiRagService>(
    () => PublicApiRagService.instance,
  );
}

/// Resolve a registered service.
///
/// Self-initializing: if the locator has not been set up yet (for example in a
/// widget test that builds a screen without going through `main()`), this
/// registers the services on first use. That guarantees screens migrated to
/// `service<T>()` behave identically to the old `X.instance` call sites in every
/// context, with no per-test setup required.
T service<T extends Object>() {
  if (!locator.isRegistered<T>()) {
    setupLocator();
  }
  return locator<T>();
}
