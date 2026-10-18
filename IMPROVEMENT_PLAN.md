# ChatBud — Improvement Plan

Status of the engineering improvement pass. ✅ = implemented in this change set
(analyzer clean; run `flutter test` to confirm green). 🔜 = deliberately staged
because it cannot be done safely without running the app / breaking changes —
each has concrete next steps.

---

## Phase 1 — Correctness & Honesty

- [x] **Message ordering / pagination bug** — `_attachFirestoreMessageListener`
  now queries `orderBy('timestamp', descending: true).limit(n)` and reverses to
  chronological order, so a growing thread always shows the newest messages
  instead of freezing at the oldest `n`. _(lib/src/services/chat_service.dart)_
- [x] **Loud AI fallback** — `GeminiService` now logs a warning/error via
  `AppLogger` whenever it serves the canned fallback instead of calling the LLM,
  so a mis-provisioned model or bad id can't masquerade as a working demo.
  _(lib/src/services/gemini_service.dart)_
- [x] **Real on-device vector memory** — added `TextEmbedder` (pure-Dart,
  deterministic feature-hashing, L2-normalized). `MemoryService` now embeds every
  memory on write and every query on read, so the cosine-similarity path is
  genuinely active (previously dead code). README updated to describe this
  accurately (lexical, not neural). _(lib/src/core/text_embedder.dart,
  lib/src/services/memory_service.dart, README.md)_
- [x] **Model selector actually drives chat** — `_streamPersonaResponse` now
  passes `GeminiService.instance.currentModel` instead of the hard-pinned
  default, so `setModel()` / `proModel` take effect. _(lib/src/services/chat_service.dart)_
- [x] Model ids confirmed correct by maintainer (`gemini-3.1-flash-lite`).

## Phase 2 — Observability & Resilience

- [x] **AppLogger** — leveled logger replacing silent `catch (_) {}` on the key
  failure paths (model init, AI stream, message stream, memory sync/delete).
  Includes a pluggable `errorReporter` hook. _(lib/src/core/app_logger.dart)_
- [x] **Memory hygiene** — de-duplication on ingest (normalized text + >0.97
  cosine), capacity cap (`maxMemories = 200`, evicting lowest
  confidence / least-recently-recalled), and a recency touch on recall.
  _(lib/src/services/memory_service.dart)_
- [x] **Firebase Crashlytics wired** — `firebase_crashlytics` added;
  `main()` registers `AppLogger.errorReporter` → `Crashlytics.recordError` and
  sets `FlutterError.onError = recordFlutterFatalError`, guarded so it stays
  inert on web and in test/offline environments. _(lib/main.dart)_
  **⚠️ Remaining manual step (platform config):** add the native config files
  — iOS `GoogleService-Info.plist`, Android `google-services.json` + the
  `com.google.gms:google-services` / Crashlytics Gradle plugins — then do a
  real crash test. Without these the Dart code compiles and no-ops; crashes
  won't upload until the platform config is present.

## Phase 3 — Architecture & Testability

- [x] **Integration test** — chat → AI reply → memory extraction flow.
  _(test/integration/chat_memory_flow_test.dart)_
- [x] **New unit tests** — `TextEmbedder` and the memory-engine upgrades
  (embedding, dedup, retrieval ranking, capacity). _(test/core/text_embedder_test.dart,
  test/services/memory_engine_test.dart)_
- [x] **Coverage in CI** — `flutter test --coverage` runs on every PR (Phase 4).
- [x] **Dependency Injection (get_it) — composition root + reference migration**
  — added `service_locator.dart` with an idempotent, self-initializing locator
  that registers each service as a lazy singleton returning the existing
  `.instance`, so `service<T>()` and `X.instance` resolve to the *same* object
  (no behavior change, existing tests stay green). `main()` calls
  `setupLocator()`. `conversation_screen.dart` migrated as the reference call
  site (11 service lookups now go through the locator). Covered by
  `test/core/service_locator_test.dart`.
  **Next steps (incremental):** migrate the remaining screens' `.instance`
  calls to `service<T>()`, then convert services to constructor-injected deps
  and register real factories (the singleton delegation is the transitional seam).
- [~] **Split god files — pure logic extracted & tested** —
  `conversation_screen.dart` 1039 → 990 lines. Side-effect-free logic pulled
  into `lib/src/screen/conversation/transcript_exporter.dart` and
  `conversation_suggestions.dart`, each unit-tested
  (`test/screens/conversation_logic_test.dart`).
  **Next steps (🔜 staged — needs the running app + widget tests):** extract the
  stateful subtrees (message list, composer wiring, report/block dialogs) into
  widgets under `lib/src/screen/conversation/`, running widget tests after each
  move. Not done blind because these are behavior-sensitive and only your
  widget-test run can confirm them. Same approach then applies to
  `persona_hub_screen.dart` (828) and `chat_service.dart` (638).

## Phase 4 — Hardening & Polish

- [x] **GitHub Actions CI** — format check, `flutter analyze`,
  `flutter test --coverage`, coverage artifact. _(.github/workflows/ci.yaml)_
- [x] **User-email read privacy — fixed** — `email` is no longer written to the
  discovery-readable `users/{uid}` doc. It now lives in an owner-only
  `users/{uid}/private/me` subdocument. Updated both writers
  (`auth_service._updateUserDocument`, `app_state.updateDisplayName`), account
  deletion (removes the private subdoc first), the `isValidUser` rules
  validator (drops `email`), and added an owner-only `match /private/{docId}`
  rule. No client read of the old `email` field existed, so nothing breaks.
  **⚠️ Deploy step:** push the updated rules (`firebase deploy --only
  firestore:rules`). Existing user docs keep a stale `email` field until next
  write — optionally run a one-off backfill to move+scrub them.
- [ ] 🔜 **`google_sign_in` 6.x → 7.x** — breaking major (the 7.x auth API is
  restructured). Do as an isolated PR with the real sign-in flow exercised on a
  device; not safe to bump blind.
  **Next steps:** `flutter pub upgrade --major-versions google_sign_in`, then
  migrate `auth_service` to the 7.x `authenticate()` API and test on iOS/Android/web.

---

### Verify this change set
```bash
flutter analyze        # expected: No issues found
flutter test           # expected: all tests pass (101 existing + new)
```
