import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/models/persona.dart';
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
    PersonaService.instance.personasNotifier.value = [...Persona.curatedPersonas];
  });

  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const PersonaHubScreen(),
    );
  }

  group('PersonaHubScreen Widget Tests', () {
    testWidgets('Renders Persona Hub title, action buttons, search, and category chips',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Persona Hub'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Athena'), findsWidgets);
    });

    testWidgets('Tapping Create Persona button opens create dialog', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Create New Persona'), findsOneWidget);
      expect(find.text('Create Persona'), findsOneWidget);
    });

    testWidgets('Displays active status and allows switching active persona',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsWidgets);
      expect(find.text('Set Active'), findsWidgets);

      await tester.tap(find.text('Set Active').first);
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsWidgets);
    });
  });
}
