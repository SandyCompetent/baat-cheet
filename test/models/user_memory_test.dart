import 'package:chatbud/src/models/user_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserMemory Model Tests', () {
    test('Constructor creates UserMemory correctly', () {
      final now = DateTime(2026, 4, 1, 10, 0);
      final mem = UserMemory(
        id: 'mem_1',
        userId: 'user_abc',
        personaId: 'athena',
        fact: 'User prefers BLoC for state management.',
        category: 'preference',
        confidence: 0.95,
        embedding: [0.1, 0.2, 0.3],
        createdAt: now,
        lastRecalledAt: now,
      );

      expect(mem.id, 'mem_1');
      expect(mem.userId, 'user_abc');
      expect(mem.personaId, 'athena');
      expect(mem.fact, 'User prefers BLoC for state management.');
      expect(mem.category, 'preference');
      expect(mem.confidence, 0.95);
      expect(mem.embedding, [0.1, 0.2, 0.3]);
    });

    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 4, 1, 10, 0);
      final mem = UserMemory(
        id: 'mem_2',
        userId: 'user_xyz',
        personaId: null,
        fact: 'Building an open-source Flutter multi-agent chat app.',
        category: 'project',
        confidence: 1.0,
        embedding: [0.5, -0.5, 0.25],
        createdAt: now,
        lastRecalledAt: now,
      );

      final map = mem.toMap();
      expect(map['id'], 'mem_2');
      expect(map['userId'], 'user_xyz');
      expect(map['personaId'], null);
      expect(map['fact'], 'Building an open-source Flutter multi-agent chat app.');
      expect(map['category'], 'project');
      expect(map['confidence'], 1.0);
      expect(map['embedding'], [0.5, -0.5, 0.25]);

      final restored = UserMemory.fromMap(map);
      expect(restored.id, mem.id);
      expect(restored.userId, mem.userId);
      expect(restored.personaId, null);
      expect(restored.fact, mem.fact);
      expect(restored.category, mem.category);
      expect(restored.confidence, 1.0);
      expect(restored.embedding, [0.5, -0.5, 0.25]);
    });

    test('copyWith updates specified fields only', () {
      final now = DateTime(2026, 4, 1);
      final mem = UserMemory(
        id: 'mem_3',
        userId: 'user_1',
        fact: 'Likes dark mode',
        createdAt: now,
        lastRecalledAt: now,
      );

      final recalledNow = DateTime(2026, 4, 2);
      final updated = mem.copyWith(
        lastRecalledAt: recalledNow,
        confidence: 0.8,
      );

      expect(updated.id, 'mem_3');
      expect(updated.fact, 'Likes dark mode');
      expect(updated.lastRecalledAt, recalledNow);
      expect(updated.confidence, 0.8);
    });
  });
}
