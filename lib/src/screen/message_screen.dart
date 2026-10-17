import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/src/widgets/message_item.dart';
import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
      ),
      body: ListView(
        children: const [
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Raja',
              txtMessage: 'i am raja',
              txtTime: '08:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Rani',
              txtMessage: 'i am rani',
              txtTime: '07:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Choor',
              txtMessage: 'i am choor',
              txtTime: '10:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Police',
              txtMessage: 'i am polic',
              txtTime: '12:00'),
        ],
      ),
    );
  }
}
