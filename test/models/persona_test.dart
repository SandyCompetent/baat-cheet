import 'package:chatbud/src/models/persona.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Persona Model Tests', () {
    test('Curated personas are preloaded with expected IDs and starter prompts',
        () {
      final curated = Persona.curatedPersonas;
      expect(curated.length, 16);
      final ids = curated.map((p) => p.id).toSet();
      expect(ids.contains('harper'), true);
      expect(ids.contains('aria'), true);
      expect(ids.contains('leo'), true);
      expect(ids.contains('athena'), true);
      expect(ids.contains('cipher'), true);
      expect(ids.contains('marcus'), true);
      expect(ids.contains('nova'), true);
      expect(ids.contains('exeter'), true);
      expect(ids.contains('openalex_rag'), true);
      expect(ids.contains('osv_rag'), true);
      expect(ids.contains('eol_rag'), true);
      expect(ids.contains('jobs_rag'), true);
      expect(ids.contains('weather_rag'), true);
      expect(ids.contains('wiki_rag'), true);
      expect(ids.contains('lexicon_rag'), true);
      expect(ids.contains('holiday_rag'), true);

      for (final p in curated) {
        expect(p.isCurated, true);
        expect(p.name.isNotEmpty, true);
        expect(p.tagline.isNotEmpty, true);
        expect(p.systemPrompt.isNotEmpty, true);
        expect(p.tags.isNotEmpty, true);
        expect(p.starterPrompts.isNotEmpty, true);
        expect(p.ragApis.isNotEmpty, true);
      }
    });

    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 6, 15, 12, 0);
      final persona = Persona(
        id: 'custom_1',
        name: 'Custom Mentor',
        tagline: 'Personal Coding Coach',
        description: 'Guides Flutter architecture',
        systemPrompt: 'You are a senior Flutter engineer mentor.',
        avatarUrl: 'https://example.com/avatar.png',
        category: 'Engineering',
        tags: ['Flutter', 'Mentorship'],
        starterPrompts: ['How do I architect a Flutter app?'],
        isCurated: false,
        creatorId: 'user_123',
        createdAt: now,
        temperature: 0.8,
      );

      final map = persona.toMap();
      expect(map['id'], 'custom_1');
      expect(map['name'], 'Custom Mentor');
      expect(map['tagline'], 'Personal Coding Coach');
      expect(map['systemPrompt'], 'You are a senior Flutter engineer mentor.');
      expect(map['avatarUrl'], 'https://example.com/avatar.png');
      expect(map['category'], 'Engineering');
      expect(map['tags'], ['Flutter', 'Mentorship']);
      expect(map['starterPrompts'], ['How do I architect a Flutter app?']);
      expect(map['isCurated'], false);
      expect(map['creatorId'], 'user_123');
      expect(map['temperature'], 0.8);

      final restored = Persona.fromMap(map);
      expect(restored.id, persona.id);
      expect(restored.name, persona.name);
      expect(restored.tagline, persona.tagline);
      expect(restored.systemPrompt, persona.systemPrompt);
      expect(restored.avatarUrl, persona.avatarUrl);
      expect(restored.category, persona.category);
      expect(restored.tags, persona.tags);
      expect(restored.starterPrompts, persona.starterPrompts);
      expect(restored.isCurated, persona.isCurated);
      expect(restored.creatorId, persona.creatorId);
      expect(restored.temperature, persona.temperature);
    });

    test('fromMap provides defaults when fields are missing', () {
      final emptyMap = <String, dynamic>{};
      final restored = Persona.fromMap(emptyMap);

      expect(restored.id, '');
      expect(restored.name, 'Unnamed Persona');
      expect(restored.category, 'General');
      expect(restored.tags.isEmpty, true);
      expect(restored.isCurated, false);
      expect(restored.temperature, 0.7);
    });

    test('copyWith updates specified fields only', () {
      final original = Persona.curatedPersonas.first;
      final updated = original.copyWith(
        name: 'Athena Prime',
        temperature: 0.2,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Athena Prime');
      expect(updated.temperature, 0.2);
      expect(updated.systemPrompt, original.systemPrompt);
      expect(updated.tagline, original.tagline);
    });
  });
}
