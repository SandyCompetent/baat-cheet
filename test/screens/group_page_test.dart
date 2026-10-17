import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/group_page.dart';
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
      home: const GroupPage(),
    );
  }

  group('GroupPage Widget Tests', () {
    testWidgets('Renders Groups title and clean empty state when no groups exist',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('No Groups Yet'), findsOneWidget);
      expect(find.text('Create a Group'), findsOneWidget);
    });

    testWidgets('Tapping create group button opens dialog and adds group',
        (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Create New Group'), findsOneWidget);
      expect(find.text('Group Name'), findsOneWidget);
      expect(find.text('Topic / Description (optional)'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Group Name'), 'Flutter Engineers');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Flutter Engineers'), findsWidgets);
      expect(find.byType(ConversationScreen), findsOneWidget);
    });
  });
}
