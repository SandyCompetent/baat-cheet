import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/persona_hub_screen.dart';
import 'package:chatbud/src/services/persona_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const PersonaHubScreen(),
    );
  }

  group('PersonaHubScreen Widget Tests', () {
    testWidgets('Renders AppBar, Active Persona Banner, and Curated Personas',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Persona Hub'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Athena'), findsWidgets);
      expect(find.text('Cipher'), findsOneWidget);
      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
    });

    testWidgets('Category chips filter personas list', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Philosophy'), findsOneWidget);

      // Tap Security filter chip
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();

      expect(find.text('Cipher'), findsWidgets);
      // Marcus is Philosophy so shouldn't be in Security list
      expect(find.text('Marcus'), findsNothing);
    });

    testWidgets('Tapping Memory Vault icon opens Long-Term Memory Vault sheet',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.psychology_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Long-Term Memory Vault'), findsOneWidget);
      expect(find.text('Facts and preferences remembered across all conversations. Retrieved dynamically via vector cosine similarity.'),
          findsOneWidget);
    });

    testWidgets('Tapping Create Persona button opens creation dialog',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Create New Persona'), findsOneWidget);
      expect(find.text('Create Persona'), findsOneWidget);
    });

    testWidgets('Tapping Set Active changes active persona banner',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Find Set Active buttons and tap the one for Cipher
      final setActiveButtons = find.text('Set Active');
      expect(setActiveButtons, findsWidgets);

      await tester.tap(setActiveButtons.at(1));
      await tester.pumpAndSettle();

      expect(PersonaService.instance.activePersonaNotifier.value.id, 'cipher');
    });
  });
}
