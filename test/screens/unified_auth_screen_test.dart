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
    testWidgets('Renders single unified form with email, password, and social buttons',
        (tester) async {
      await tester.pumpWidget(buildApp());

      // Brand & Header
      expect(find.text('ChatBud'), findsOneWidget);
      expect(find.text('Welcome to ChatBud'), findsOneWidget);
      expect(
        find.text('Enter your email to sign in or create an account.'),
        findsOneWidget,
      );

      // Single Form fields
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      // Social Auth Buttons
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);

      // Ensure NO legacy mode toggles exist
      expect(find.text('Already have an account? Sign In'), findsNothing);
      expect(find.text("Don't have an account? "), findsNothing);
      expect(find.text('Sign Up'), findsNothing);

      // Legal links
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('Shows error when submitting invalid email', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.enterText(find.byType(TextField).first, 'invalidemail');
      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Shows error when submitting password under 6 characters',
        (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.enterText(
          find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters.'),
          findsOneWidget);
    });

    testWidgets('Tapping Forgot password opens reset dialog', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Link'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel closes dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });
  });
}
