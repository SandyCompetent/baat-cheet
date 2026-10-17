import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/auth/unified_auth_screen.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const UnifiedAuthScreen(),
    );
  }

  group('UnifiedAuthScreen Widget Tests', () {
    testWidgets('Renders header and email input field', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Welcome to ChatBud'), findsOneWidget);
      expect(
        find.text('Enter your email to sign in or create an account'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
