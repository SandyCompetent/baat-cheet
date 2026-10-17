import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/screen/splash_screen.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget home) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: home,
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders ChatBud branding text and version', (tester) async {
      await tester.pumpWidget(
        buildApp(const SplashScreen(redirectDelay: Duration(seconds: 10))),
      );

      expect(find.text(appName), findsOneWidget);
      expect(find.text(appVersion), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('Redirects to Home route after redirectDelay', (tester) async {
      await tester.pumpWidget(
        buildApp(const SplashScreen(redirectDelay: Duration(milliseconds: 50))),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsWidgets);
    });
  });
}
