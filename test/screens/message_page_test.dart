import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/message_page.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildApp() {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const MessagePage(),
    );
  }

  group('MessagePage Widget Tests', () {
    testWidgets('Renders app title, filter chips, and conversation list',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('ChatBud AI Assistant'), findsOneWidget);
    });

    testWidgets('Tapping search icon toggles search input bar', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Filtering by Unread chip displays unread conversations',
        (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      expect(find.text('ChatBud AI Assistant'), findsOneWidget);
      expect(find.text('Bruce Wayne'), findsNothing);
    });
  });
}
