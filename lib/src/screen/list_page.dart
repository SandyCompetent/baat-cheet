import 'package:chatbud/src/models/chat_message.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        title: Text(
          'Saved Messages',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.borderSubtle),
        ),
      ),
      body: ValueListenableBuilder<List<ChatMessage>>(
        valueListenable: ChatService.instance.savedMessagesNotifier,
        builder: (context, saved, _) {
          if (saved.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.accentSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      color: context.accent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing Saved Yet',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Long-press any message in a chat and select "Save to Bookmarks" to reference it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            itemCount: saved.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = saved[index];
              return Container(
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderSubtle),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: context.accentSubtle,
                              child: Text(
                                msg.senderName.isNotEmpty
                                    ? msg.senderName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              msg.senderName,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          msg.formattedTime,
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      msg.text,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: context.borderSubtle),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Copied to clipboard'),
                                backgroundColor: context.bgElevated,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy',
                              style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            ChatService.instance.toggleBookmark(msg);
                          },
                          icon: Icon(
                            Icons.bookmark_remove_rounded,
                            size: 16,
                            color: context.statusDanger,
                          ),
                          label: Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.statusDanger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
