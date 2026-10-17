import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/widgets/message_item.dart';
import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
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
        children: [
          MessageItem(
            imgRef: appLogo,
            txtPersonName: 'ChatBud AI',
            txtMessage: 'How can I assist you today? Tap to chat!',
            txtTime: 'Now',
            isAi: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationScreen(
                    title: 'ChatBud AI Assistant',
                    isAi: true,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 70),
          MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Oswald Cobblepot',
            txtMessage: 'i am Oswald Cobblepot',
            txtTime: '08:00',
            onTap: () => _openConversation(context, 'Oswald Cobblepot'),
          ),
          MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Fish Mooney',
            txtMessage: 'i am Fish Mooney',
            txtTime: '07:00',
            onTap: () => _openConversation(context, 'Fish Mooney'),
          ),
          MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Bruce Wayne',
            txtMessage: 'i am Bruce Wayne',
            txtTime: '10:00',
            onTap: () => _openConversation(context, 'Bruce Wayne'),
          ),
          MessageItem(
            imgRef: appLogo,
            txtPersonName: 'Barbara Kean',
            txtMessage: 'i am Barbara Kean',
            txtTime: '12:00',
            onTap: () => _openConversation(context, 'Barbara Kean'),
          ),
        ],
      ),
    );
  }

  void _openConversation(BuildContext context, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          title: name,
          isAi: false,
        ),
      ),
    );
  }
}
