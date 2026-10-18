import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/memory_page.dart';
import 'package:chatbud/src/services/memory_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    MemoryService.instance.memoriesNotifier.value = [];
  });

  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const MemoryPage(),
    );
  }

  group('MemoryPage Widget Tests', () {
    testWidgets('Renders Memory Vault header, architecture banner, and search field',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Long-Term Memory'), findsOneWidget);
      expect(find.text('Two-Layer Memory Engine'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Can add a new memory fact manually', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final addField = find.widgetWithText(
          TextField, 'Add a fact (e.g. "I work at Google", "Likes Dart")');
      expect(addField, findsOneWidget);

      await tester.enterText(addField, 'Prefers clean architecture');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Prefers clean architecture'), findsOneWidget);
      expect(find.text('MANUAL'), findsWidgets);
    });
  });
}
