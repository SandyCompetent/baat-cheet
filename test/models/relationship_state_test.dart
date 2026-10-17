import 'package:chatbud/src/models/relationship_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RelationshipState Model Tests', () {
    test('Constructor creates RelationshipState with defaults', () {
      final now = DateTime(2026, 4, 1);
      final state = RelationshipState(
        personaId: 'athena',
        lastInteraction: now,
      );

      expect(state.personaId, 'athena');
      expect(state.trustLevel, 1);
      expect(state.mood, 'Supportive');
      expect(state.interactionCount, 0);
      expect(state.lastInteraction, now);
      expect(state.notes, null);
    });

    test('trustLevel clamps within 1 to 10 range', () {
      final now = DateTime(2026, 4, 1);
      final low = RelationshipState(
        personaId: 'marcus',
        trustLevel: -5,
        lastInteraction: now,
      );
      expect(low.trustLevel, 1);

      final high = RelationshipState(
        personaId: 'cipher',
        trustLevel: 100,
        lastInteraction: now,
      );
      expect(high.trustLevel, 10);

      final updated = high.copyWith(trustLevel: 25);
      expect(updated.trustLevel, 10);
    });

    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 4, 1, 15, 30);
      final state = RelationshipState(
        personaId: 'nova',
        trustLevel: 7,
        mood: 'Enthusiastic',
        interactionCount: 42,
        lastInteraction: now,
        notes: 'User discussed marketing launch strategy.',
      );

      final map = state.toMap();
      expect(map['personaId'], 'nova');
      expect(map['trustLevel'], 7);
      expect(map['mood'], 'Enthusiastic');
      expect(map['interactionCount'], 42);
      expect(map['notes'], 'User discussed marketing launch strategy.');

      final restored = RelationshipState.fromMap(map);
      expect(restored.personaId, state.personaId);
      expect(restored.trustLevel, 7);
      expect(restored.mood, 'Enthusiastic');
      expect(restored.interactionCount, 42);
      expect(restored.notes, state.notes);
    });
  });
}
