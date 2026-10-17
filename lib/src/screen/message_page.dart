import 'package:baatcheet/project_meta_data.dart';
import 'package:baatcheet/src/widgets/message_item.dart';
import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Edit",
          style: TextStyle(
            color: Colors.red,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            color: Colors.redAccent,
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: const [
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Oswald obblepot',
              txtMessage: 'i am Oswald obblepot',
              txtTime: '08:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Fish Mooney',
              txtMessage: 'i am Fish Mooney',
              txtTime: '07:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Bruce Wayne',
              txtMessage: 'i am Bruce Wayn',
              txtTime: '10:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Barbara Kean',
              txtMessage: 'i am Barbara Kean',
              txtTime: '12:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Barbara Kean',
              txtMessage: 'i am Barbara Kean',
              txtTime: '12:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Barbara Kean',
              txtMessage: 'i am Barbara Kean',
              txtTime: '12:00'),
          MessageItem(
              imgRef: appLogo,
              txtPersonName: 'Barbara Kean',
              txtMessage: 'i am Barbara Kean',
              txtTime: '12:00'),
        ],
      ),
    );
  }
}
