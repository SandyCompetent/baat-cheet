import 'package:chatbud/main.dart';
import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'system',
      'guest_display_name': 'ChatBud User',
    });
    await StorageService.init();
  });

  group('ChatBud Main App Integration Tests', () {
    testWidgets('App renders MyHomePage with bottom navigation bar and tabs',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          onGenerateRoute: RouteGenerator.generateRoute,
          home: const MyHomePage(),
        ),
      );

      // Verify initial tab (Chats)
      expect(find.text('Messages'), findsOneWidget);

      // Tap 'Groups' tab in bottom bar
      await tester.tap(find.byIcon(Icons.group_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('No Groups Yet'), findsOneWidget);

      // Tap 'Saved' tab in bottom bar
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('Nothing Saved Yet'), findsOneWidget);

      // Tap 'Profile' tab in bottom bar
      await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('Theme Appearance'), findsOneWidget);
    });
  });
}
