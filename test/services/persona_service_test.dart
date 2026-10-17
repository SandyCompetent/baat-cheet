import 'package:chatbud/src/models/persona.dart';
import 'package:chatbud/src/services/persona_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PersonaService Tests', () {
    test('Initializes with curated personas', () {
      final service = PersonaService.instance;
      final personas = service.personasNotifier.value;

      expect(personas.length >= 4, true);
      expect(personas.any((p) => p.id == 'athena'), true);
      expect(personas.any((p) => p.id == 'cipher'), true);
      expect(personas.any((p) => p.id == 'marcus'), true);
      expect(personas.any((p) => p.id == 'nova'), true);
    });

    test('getPersonaById returns matching persona or fallback', () {
      final service = PersonaService.instance;
      final cipher = service.getPersonaById('cipher');
      expect(cipher.id, 'cipher');
      expect(cipher.name, 'Cipher');

      final unknown = service.getPersonaById('non_existent_id');
      expect(unknown.id, Persona.curatedPersonas.first.id);
    });

    test('findPersonaByName matches by name case-insensitively and handles @ symbol', () {
      final service = PersonaService.instance;
      final athena = service.findPersonaByName('@athena');
      expect(athena, isNotNull);
      expect(athena!.id, 'athena');

      final marcus = service.findPersonaByName('Marcus');
      expect(marcus, isNotNull);
      expect(marcus!.id, 'marcus');
    });

    test('createCustomPersona and deleteCustomPersona flow', () async {
      final service = PersonaService.instance;
      final initialCount = service.personasNotifier.value.length;

      final created = await service.createCustomPersona(
        name: 'Zen Master',
        tagline: 'Mindfulness Guide',
        description: 'Brings focus and presence to conversation.',
        systemPrompt: 'You are a Zen master. Speak simply and profoundly.',
        category: 'Philosophy',
        tags: ['Zen', 'Mindfulness'],
      );

      expect(created.name, 'Zen Master');
      expect(service.personasNotifier.value.length, initialCount + 1);
      expect(service.getPersonaById(created.id).name, 'Zen Master');

      // Cannot delete curated personas
      await service.deleteCustomPersona('athena');
      expect(service.personasNotifier.value.any((p) => p.id == 'athena'), true);

      // Delete the created custom persona
      await service.deleteCustomPersona(created.id);
      expect(service.personasNotifier.value.length, initialCount);
    });

    test('setActivePersona updates activePersonaNotifier', () async {
      final service = PersonaService.instance;
      await service.setActivePersona('marcus');
      expect(service.activePersonaNotifier.value.id, 'marcus');

      await service.setActivePersona('athena');
      expect(service.activePersonaNotifier.value.id, 'athena');
    });
  });
}
