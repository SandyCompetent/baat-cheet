import 'package:chatbud/src/widgets/message_item.dart';
import 'package:flutter/material.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final List<String> _messages = ["Hi! How are you?"];

  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final text = _textEditingController.text;
    _textEditingController.clear();
    setState(() {
      _messages.add(text);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          curve: Curves.ease, duration: const Duration(milliseconds: 500));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.redAccent,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final bool reverse = index % 2 == 0;
                return _buildMessage(reverse, _messages[index]);
              },
            ),
          ),
          const Divider(height: 2.0),
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(bool reverse, String messageText) {
    return Align(
      alignment: reverse ? Alignment.centerRight : Alignment.centerLeft,
      child: MessageItem(
        imgRef: 'assets/app_logo.png',
        txtPersonName: "User",
        txtMessage: messageText,
        txtTime: "12:00",
      ),
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: TextField(
              onChanged: (text) => setState(() {}),
              decoration: const InputDecoration.collapsed(
                hintText: "Type a message",
              ),
              controller: _textEditingController,
            ),
          ),
        ),
        IconButton(
          color: Theme.of(context).primaryColor,
          icon: const Icon(
            Icons.send,
          ),
          onPressed: _textEditingController.text.isNotEmpty
              ? _handleSendMessage
              : null,
        )
      ],
    );
  }
}
