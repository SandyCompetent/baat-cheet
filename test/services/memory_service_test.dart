import 'package:chatbud/src/services/memory_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('MemoryService Tests', () {
    test('cosineSimilarity computes exact vector similarity', () {
      // Identical vectors -> 1.0
      expect(
        MemoryService.cosineSimilarity([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]),
        closeTo(1.0, 0.0001),
      );

      // Orthogonal vectors -> 0.0
      expect(
        MemoryService.cosineSimilarity([1.0, 0.0], [0.0, 1.0]),
        closeTo(0.0, 0.0001),
      );

      // Opposing vectors -> -1.0
      expect(
        MemoryService.cosineSimilarity([1.0, 0.0], [-1.0, 0.0]),
        closeTo(-1.0, 0.0001),
      );

      // Empty or mismatched -> 0.0
      expect(MemoryService.cosineSimilarity([], []), 0.0);
      expect(MemoryService.cosineSimilarity([1.0], [1.0, 2.0]), 0.0);
    });

    test('addMemory, retrieveRelevantMemories, and deleteMemory flow', () async {
      final service = MemoryService.instance;

      final memory = await service.addMemory(
        fact: 'User prefers riverpod architecture over provider in flutter.',
        category: 'preference',
        personaId: 'athena',
      );

      expect(service.memoriesNotifier.value.contains(memory), true);

      // Retrieve by keyword overlap
      final retrieved = service.retrieveRelevantMemories(
        query: 'What architecture in flutter should I use for state?',
        personaId: 'athena',
      );

      expect(retrieved.isNotEmpty, true);
      expect(retrieved.first.fact.contains('riverpod'), true);

      // Clean up
      await service.deleteMemory(memory.id);
      expect(service.memoriesNotifier.value.any((m) => m.id == memory.id), false);
    });

    test('recordInteraction updates trustLevel and interaction count', () async {
      final service = MemoryService.instance;

      final initial = service.getRelationshipState('cipher');
      expect(initial.personaId, 'cipher');
      final startCount = initial.interactionCount;

      await service.recordInteraction('cipher', moodOverride: 'Analytical');
      final updated = service.getRelationshipState('cipher');

      expect(updated.interactionCount, startCount + 1);
      expect(updated.mood, 'Analytical');
    });

    test('buildSystemPrompt injects memory context and relationship state', () async {
      final service = MemoryService.instance;

      final memory = await service.addMemory(
        fact: 'User is preparing to deploy an open-source Flutter app on GitHub.',
        category: 'project',
        personaId: 'nova',
      );

      final prompt = service.buildSystemPrompt(
        basePrompt: 'You are Nova, creative strategist.',
        personaId: 'nova',
        currentQuery: 'Help me draft an open-source README for GitHub.',
      );

      expect(prompt.contains('You are Nova, creative strategist.'), true);
      expect(prompt.contains('CONTEXT & LONG-TERM MEMORY'), true);
      expect(prompt.contains('Relationship with user'), true);
      expect(prompt.contains('deploy an open-source Flutter app'), true);

      await service.deleteMemory(memory.id);
    });
  });
}
