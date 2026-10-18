import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/screen/login_screen.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const LoginScreen(),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets(
        'Renders ChatBud header, email/password fields, and Sign In button',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('ChatBud'), findsOneWidget);
      expect(find.text('Connecting to the ones you love'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Toggles password visibility icon on tap', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('Tapping Sign In button navigates to Home screen',
        (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Chats'), findsOneWidget);
    });
  });
}
