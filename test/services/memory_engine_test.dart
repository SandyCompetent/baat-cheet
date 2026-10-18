import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/services/memory_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('MemoryService engine upgrades', () {
    test('addMemory auto-generates an on-device embedding', () async {
      final service = MemoryService.instance;
      final mem = await service.addMemory(
        fact: 'User is building a multi-agent AI workspace in Flutter.',
        personaId: 'engine_test_embed',
      );
      expect(mem.embedding, isNotNull);
      expect(mem.embedding!.isNotEmpty, isTrue);
      await service.deleteMemory(mem.id);
    });

    test('duplicate facts are de-duplicated, not appended', () async {
      final service = MemoryService.instance;
      const persona = 'engine_test_dedup';
      final before = service.memoriesNotifier.value
          .where((m) => m.personaId == persona)
          .length;

      final first = await service.addMemory(
        fact: 'User prefers dark mode themes.',
        personaId: persona,
      );
      // Same fact with different punctuation/casing -> treated as duplicate.
      final second = await service.addMemory(
        fact: 'user prefers dark mode themes',
        personaId: persona,
      );

      final after = service.memoriesNotifier.value
          .where((m) => m.personaId == persona)
          .length;

      expect(second.id, first.id, reason: 'duplicate should reuse existing id');
      expect(after - before, 1, reason: 'only one memory should be stored');

      await service.deleteMemory(first.id);
    });

    test('retrieval ranks by semantic vector + keyword overlap', () async {
      final service = MemoryService.instance;
      const persona = 'engine_test_retrieval';
      final a = await service.addMemory(
        fact: 'User is preparing a promotion case for a senior engineer role.',
        personaId: persona,
      );
      final b = await service.addMemory(
        fact: 'User enjoys hiking in the Lake District on weekends.',
        personaId: persona,
      );

      final results = service.retrieveRelevantMemories(
        query: 'help me plan my promotion to senior engineer',
        personaId: persona,
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.fact.contains('promotion'), isTrue);

      await service.deleteMemory(a.id);
      await service.deleteMemory(b.id);
    });

    test('vault stays bounded at maxMemories', () async {
      final service = MemoryService.instance;
      const persona = 'engine_test_cap';
      for (var i = 0; i < MemoryService.maxMemories + 25; i++) {
        await service.addMemory(
          fact: 'Distinct episodic fact number $i about topic $i.',
          personaId: persona,
          confidence: 1.0,
        );
      }
      expect(
        service.memoriesNotifier.value.length,
        lessThanOrEqualTo(MemoryService.maxMemories),
      );
    });
  });
}
