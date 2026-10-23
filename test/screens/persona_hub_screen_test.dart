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
    PersonaService.instance.personasNotifier.value = [
      ...Persona.curatedPersonas
    ];
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
    testWidgets(
        'Renders Persona Hub title, action buttons, search, and category chips',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Persona Hub'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('HR & Talent'), findsOneWidget);
      expect(find.text('Productivity'), findsOneWidget);
      expect(find.text('Harper'), findsWidgets);
    });

    testWidgets(
        'Tapping Create Persona button opens create dialog with 1-tap presets',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Create New Persona'), findsOneWidget);
      expect(find.text('1-Tap Templates (No prompt writing needed):'),
          findsOneWidget);
      expect(find.text('🎯 HR Recruiter'), findsOneWidget);
      expect(find.text('Create Persona'), findsOneWidget);

      // Tap preset to auto-fill
      await tester.tap(find.text('🎯 HR Recruiter'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Jordan'), findsOneWidget);
      expect(
          find.widgetWithText(
              TextFormField, 'Talent Screener & Interview Prep'),
          findsOneWidget);
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

    testWidgets(
        'Filtering by Academic category shows Exeter Academic persona and Campus Live button',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Academic'), findsOneWidget);
      await tester.tap(find.text('Academic'));
      await tester.pumpAndSettle();

      expect(find.text('Exeter Academic'), findsOneWidget);
      expect(find.text('Campus Live'), findsOneWidget);
      expect(find.text('Live RAG'), findsWidgets);
    });

    testWidgets(
        'Filtering by Grounded RAG category shows dedicated Grounded RAG Engine personas',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Grounded RAG'), findsOneWidget);
      await tester.tap(find.text('Grounded RAG'));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Alexia (OpenAlex RAG)'), findsOneWidget);
      expect(find.text('Sentinel (Google OSV RAG)'), findsOneWidget);
      expect(find.text('Live RAG'), findsWidgets);

      // Tap Live RAG button to open the Grounded RAG Engine inspector sheet
      await tester.tap(find.text('Live RAG').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Dr. Alexia (OpenAlex RAG) · Grounded RAG Engine'),
        findsOneWidget,
      );
    });
  });
}
