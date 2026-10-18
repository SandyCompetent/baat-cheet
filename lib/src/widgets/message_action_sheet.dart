import 'package:flutter/material.dart';
import '../../theme_data.dart';
import '../models/chat_message.dart';

class MessageActionSheet extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.onCopy,
    required this.onBookmark,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.copy_rounded, color: context.accent),
            title: const Text('Copy Text'),
            onTap: () {
              Navigator.pop(context);
              onCopy();
            },
          ),
          ListTile(
            leading: Icon(
              message.isBookmarked
                  ? Icons.bookmark_remove_rounded
                  : Icons.bookmark_add_rounded,
              color: context.accent,
            ),
            title: Text(
              message.isBookmarked
                  ? 'Remove from Bookmarks'
                  : 'Save to Bookmarks',
            ),
            onTap: () {
              Navigator.pop(context);
              onBookmark();
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
            title: const Text('Report Objectionable Content'),
            onTap: () {
              Navigator.pop(context);
              onReport();
            },
          ),
          if (!message.isUser)
            ListTile(
              leading: Icon(Icons.block_rounded, color: context.statusDanger),
              title: Text(
                'Block ${message.senderName}',
                style: TextStyle(color: context.statusDanger),
              ),
              onTap: () {
                Navigator.pop(context);
                onBlock();
              },
            ),
          ListTile(
            leading:
                Icon(Icons.delete_outline_rounded, color: context.statusDanger),
            title: Text(
              'Delete Message',
              style: TextStyle(color: context.statusDanger),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
