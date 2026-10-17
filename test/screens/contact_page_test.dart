import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/app_state.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/contact_page.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'guest_display_name': 'Tester User',
    });
    await AppState.instance.initialize();
  });

  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const ContactPage(),
    );
  }

  group('ContactPage Widget Tests', () {
    testWidgets('Renders user display name, status, and settings options',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Tester User'), findsWidgets);
      expect(find.text('Guest Mode'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Theme Appearance'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
      expect(find.text('Help & Documentation'), findsOneWidget);
    });

    testWidgets('Tapping Theme Appearance opens theme selection dialog',
        (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Theme Appearance'));
      await tester.pumpAndSettle();

      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light Slate'), findsOneWidget);
      expect(find.text('Dark Slate (OLED)'), findsOneWidget);
    });

    testWidgets('Tapping Help & Documentation opens help dialog',
        (tester) async {
      await tester.pumpWidget(buildApp());

      // Scroll down so Help & Documentation is centered on screen
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();

      final finder = find.text('Help & Documentation');
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('ChatBud Help & Support'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
