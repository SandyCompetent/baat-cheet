import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/src/screen/message_screen.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageScreen Widget Tests', () {
    testWidgets('Renders app title and message list items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: const MessageScreen(),
        ),
      );

      expect(find.text(appName), findsOneWidget);
      expect(find.text('Raja'), findsOneWidget);
      expect(find.text('i am raja'), findsOneWidget);
      expect(find.text('Rani'), findsOneWidget);
      expect(find.text('Choor'), findsOneWidget);
      expect(find.text('Police'), findsOneWidget);
    });
  });
}
