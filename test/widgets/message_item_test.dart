import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/src/widgets/message_item.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('MessageItem Widget Tests', () {
    testWidgets('Renders standard message item with person name and message preview',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Bruce Wayne',
            txtMessage: 'The Bat-Signal is active',
            txtTime: '21:00',
            unreadCount: 0,
          ),
        ),
      );

      expect(find.text('Bruce Wayne'), findsOneWidget);
      expect(find.text('The Bat-Signal is active'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
      expect(find.text('AI'), findsNothing);
    });

    testWidgets('Renders AI badge when isAi is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MessageItem(
            imgRef: appLogo,
            txtPersonName: 'ChatBud AI',
            txtMessage: 'How can I assist you?',
            txtTime: 'Now',
            isAi: true,
          ),
        ),
      );

      expect(find.text('ChatBud AI'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
    });

    testWidgets('Renders unread count badge when unreadCount > 0',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Oswald',
            txtMessage: 'Iceberg Lounge update',
            txtTime: '10:30',
            unreadCount: 5,
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Triggers onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Interactive Item',
            txtMessage: 'Tap me',
            txtTime: '12:00',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Interactive Item'));
      expect(tapped, true);
    });
  });
}
