import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/screen/list_page.dart';
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
      home: const ListPage(),
    );
  }

  group('ListPage Widget Tests', () {
    testWidgets('Renders Saved Messages header title', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Saved Messages'), findsOneWidget);
    });

    testWidgets('Renders empty state message when no bookmarks saved',
        (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Nothing Saved Yet'), findsOneWidget);
      expect(
        find.text(
            'Long-press any message in a chat and select "Save to Bookmarks" to reference it here.'),
        findsOneWidget,
      );
    });
  });
}
