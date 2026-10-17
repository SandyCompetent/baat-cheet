import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/src/models/conversation.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/widgets/message_item.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  int _filterIndex = 0;
  final _filters = ['All', 'Unread', 'Groups'];

  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Conversation> _applyFilterAndSearch(List<Conversation> raw) {
    return raw.where((conv) {
      // 1. Filter tab
      if (_filterIndex == 1 && conv.unreadCount == 0) return false;
      if (_filterIndex == 2 && !conv.isGroup) return false;

      // 2. Search query
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = conv.title.toLowerCase().contains(_searchQuery);
        final matchesMsg = conv.lastMessage.toLowerCase().contains(_searchQuery);
        return matchesTitle || matchesMsg;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: context.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search chats or messages…',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Text(
                'Messages',
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: context.accent,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchCtrl.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
            tooltip: _isSearching ? 'Close Search' : 'Search (⌘K)',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.borderSubtle),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: context.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final selected = i == _filterIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? context.accentSubtle
                            : context.bgElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? context.accent.withValues(alpha: 0.4)
                              : context.borderSubtle,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          color: selected ? context.accent : context.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Divider(height: 1, color: context.borderSubtle),
          Expanded(
            child: ValueListenableBuilder<List<Conversation>>(
              valueListenable: ChatService.instance.conversationsNotifier,
              builder: (context, conversations, _) {
                final visible = _applyFilterAndSearch(conversations);

                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: context.accentSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.chat_bubble_outline_rounded,
                            color: context.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No chats match "$_searchQuery"'
                              : 'No conversations found',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching by a different name or keyword'
                              : 'Start a new conversation to begin',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: visible.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, indent: 74, color: context.borderSubtle),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return MessageItem(
                      imgRef: appLogo,
                      txtPersonName: item.title,
                      txtMessage: item.lastMessage,
                      txtTime: item.lastTime,
                      isAi: item.isAi,
                      unreadCount: item.unreadCount,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConversationScreen(
                              conversationId: item.id,
                              title: item.title,
                              isAi: item.isAi,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
