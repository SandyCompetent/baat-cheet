import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/auth/unified_auth_screen.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteGenerator Tests', () {
    test('Generates SplashScreen for splashRoute', () {
      final route = RouteGenerator.generateRoute(
        const RouteSettings(name: splashRoute),
      ) as MaterialPageRoute;

      final widget = route.builder(DummyBuildContext());
      expect(widget, isA<SplashScreen>());
    });

    testWidgets('Generates UnifiedAuthScreen for loginRoute', (tester) async {
      final route = RouteGenerator.generateRoute(
        const RouteSettings(name: loginRoute),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.push(context, route),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(UnifiedAuthScreen), findsOneWidget);
    });

    testWidgets('Generates ConversationScreen for converRoute', (tester) async {
      final route = RouteGenerator.generateRoute(
        const RouteSettings(name: converRoute),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.push(context, route),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationScreen), findsOneWidget);
    });

    testWidgets('Generates PersonaHubScreen for personaHubRoute', (tester) async {
      final route = RouteGenerator.generateRoute(
        const RouteSettings(name: personaHubRoute),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.push(context, route),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('Persona Hub'), findsOneWidget);
    });

    testWidgets('Generates fallback route for unknown route name', (tester) async {
      final route = RouteGenerator.generateRoute(
        const RouteSettings(name: '/unknown_path'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.push(context, route),
                child: const Text('Go'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

class DummyBuildContext extends Fake implements BuildContext {}
