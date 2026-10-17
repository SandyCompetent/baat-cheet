import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/widgets/attachment_sheet.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttachmentSheet Widget Tests', () {
    testWidgets('Renders all share options in bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: AttachmentSheet(
              onSelect: (type, name) {},
            ),
          ),
        ),
      );

      expect(find.text('Share Content'), findsOneWidget);
      expect(find.text('Photos & Videos'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('Selecting an option invokes onSelect callback', (tester) async {
      AttachmentType? selectedType;
      String? selectedName;

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: AttachmentSheet(
              onSelect: (type, name) {
                selectedType = type;
                selectedName = name;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      expect(selectedType, AttachmentType.location);
      expect(selectedName, 'Location');
    });
  });
}
