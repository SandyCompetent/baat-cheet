import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../theme_data.dart';
import '../core/app_state.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isAi;

  const ConversationScreen({
    super.key,
    this.conversationId = 'ai_assistant',
    this.title = 'ChatBud AI Assistant',
    this.isAi = true,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final ValueNotifier<List<ChatMessage>> _messagesNotifier;

  bool _isTyping = false;
  bool _hasText = false;
  bool _showScrollDown = false;
  static const double _scrollThreshold = 120;

  @override
  void initState() {
    super.initState();
    _messagesNotifier =
        ChatService.instance.getMessagesNotifier(widget.conversationId);
    ChatService.instance.markAsRead(widget.conversationId);

    _textCtrl.addListener(_onTextChanged);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _setTyping(false);
    _textCtrl
      ..removeListener(_onTextChanged)
      ..dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _textCtrl.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
      _setTyping(has);
    }
  }

  void _setTyping(bool isTyping) {
    final uid = AppState.instance.firebaseUser?.uid ?? 'guest';
    ChatService.instance.setTypingStatus(widget.conversationId, uid, isTyping);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final distanceFromBottom =
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset;
    final show = distanceFromBottom > _scrollThreshold;
    if (show != _showScrollDown) setState(() => _showScrollDown = show);
  }

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _setTyping(false);

    final sender = AppState.instance.displayName;
    final uid = AppState.instance.firebaseUser?.uid;

    ChatService.instance.sendMessage(
      conversationId: widget.conversationId,
      text: text,
      senderName: sender,
      senderId: uid,
    );

    HapticFeedback.lightImpact();
    _scrollToBottom(force: true);

    if (widget.isAi) {
      setState(() => _isTyping = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _isTyping = false);
        _scrollToBottom();
      });
    }
  }

  void _sendStarter(String text) {
    _textCtrl.text = text;
    _handleSend();
  }

  void _scrollToBottom({bool force = false}) {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_scrollCtrl.hasClients) return;
      final distanceFromBottom =
          _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset;
      if (force || distanceFromBottom <= _scrollThreshold) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMessageLongPress(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MessageActionSheet(
        message: msg,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: msg.text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Message copied to clipboard'),
              backgroundColor: context.bgElevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onBookmark: () {
          ChatService.instance.toggleBookmark(msg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg.isBookmarked
                    ? 'Saved to bookmarks'
                    : 'Removed from bookmarks',
              ),
              backgroundColor: context.bgElevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onDelete: () {
          ChatService.instance.deleteMessage(widget.conversationId, msg.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Message deleted'),
              backgroundColor: context.bgElevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onReport: () {
          _showReportDialog(msg);
        },
        onBlock: () {
          _confirmBlockUser(msg.senderName);
        },
      ),
    );
  }

  void _showReportDialog(ChatMessage msg) {
    final reasons = [
      'Inappropriate or offensive content',
      'Harassment or hate speech',
      'Spam or phishing',
      'Other policy violation',
    ];
    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Our moderation team reviews reported content within 24 hours. Please select a reason:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons
                      .map((r) => RadioListTile<String>(
                            title: Text(r, style: const TextStyle(fontSize: 13)),
                            value: r,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.statusDanger),
              onPressed: () {
                ChatService.instance.reportContent(
                  reportedUserId: msg.senderName,
                  messageId: msg.id,
                  reason: selectedReason,
                  messageText: msg.text,
                  reporterId: AppState.instance.firebaseUser?.uid,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Thank you for keeping ChatBud safe.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlockUser(String senderName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block $senderName?'),
        content: Text(
          'You will no longer see messages from $senderName. You can unblock users in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.statusDanger),
            onPressed: () {
              ChatService.instance.blockUser(senderName);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$senderName has been blocked.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  _BubblePosition _bubblePosition(List<ChatMessage> messages, int index) {
    final msg = messages[index];
    final prev = index > 0 ? messages[index - 1] : null;
    final next = index < messages.length - 1 ? messages[index + 1] : null;

    final samePrev = prev != null && prev.isUser == msg.isUser;
    final sameNext = next != null && next.isUser == msg.isUser;

    if (!samePrev && !sameNext) return _BubblePosition.solo;
    if (!samePrev && sameNext) return _BubblePosition.first;
    if (samePrev && sameNext) return _BubblePosition.middle;
    return _BubblePosition.last;
  }

  BorderRadius _bubbleRadius(bool isUser, _BubblePosition pos) {
    const r18 = Radius.circular(18);
    const r4 = Radius.circular(4);

    return switch (pos) {
      _BubblePosition.solo => const BorderRadius.all(Radius.circular(18)),
      _BubblePosition.first => isUser
          ? const BorderRadius.only(
              topLeft: r18, topRight: r18, bottomLeft: r18, bottomRight: r4)
          : const BorderRadius.only(
              topLeft: r18, topRight: r18, bottomLeft: r4, bottomRight: r18),
      _BubblePosition.middle => isUser
          ? const BorderRadius.only(
              topLeft: r18, topRight: r4, bottomLeft: r18, bottomRight: r4)
          : const BorderRadius.only(
              topLeft: r4, topRight: r18, bottomLeft: r4, bottomRight: r18),
      _BubblePosition.last => isUser
          ? const BorderRadius.only(
              topLeft: r18, topRight: r4, bottomLeft: r18, bottomRight: r18)
          : const BorderRadius.only(
              topLeft: r4, topRight: r18, bottomLeft: r18, bottomRight: r18),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AppState.instance.firebaseUser?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: context.bgCanvas,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassHeader(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: _messagesNotifier,
                  builder: (context, messages, _) {
                    return _buildMessageFeed(messages);
                  },
                ),
              ),
              StreamBuilder<bool>(
                stream: ChatService.instance
                    .listenTypingStatus(widget.conversationId, currentUid),
                builder: (context, snapshot) {
                  final typing = _isTyping || (snapshot.data == true);
                  if (typing) {
                    return _buildTypingIndicator();
                  }
                  return const SizedBox.shrink();
                },
              ),
              _buildFloatingComposer(),
            ],
          ),
          if (_showScrollDown)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(child: _buildScrollDownPill()),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: context.bgGlass,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: context.accent,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: context.accentSubtle,
                          child: widget.isAi
                              ? Icon(Icons.smart_toy_rounded,
                                  color: context.accent, size: 20)
                              : Icon(Icons.person_rounded,
                                  color: context.accent, size: 20),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: context.statusOnline,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.bgSurface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _isTyping
                                ? 'Typing...'
                                : (widget.isAi ? 'Online • Gemini AI' : 'Online'),
                            style: TextStyle(
                              color: _isTyping
                                  ? context.accent
                                  : context.statusOnline,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: context.accent,
                        size: 22,
                      ),
                      onPressed: _showInfoDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.title),
        content: Text(
          widget.isAi
              ? 'ChatBud AI Assistant is powered by Google Gemini API with token streaming. Ask any question or draft messages in real time.'
              : 'End-to-end cloud synchronized conversation with ${widget.title}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFeed(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollCtrl,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 56 + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        final pos = _bubblePosition(messages, i);
        final topGap = (i > 0 && messages[i - 1].isUser != msg.isUser)
            ? 16.0
            : 4.0;
        return Padding(
          padding: EdgeInsets.only(top: topGap),
          child: _buildBubbleRow(msg, pos),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final starters = widget.isAi
        ? ['Say hello 👋', 'Help me draft a message', 'Tell me about Slate Theme']
        : ['Say hello 👋', 'How are you doing?', 'Let\'s catch up!'];

    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 56 + 48,
        bottom: 120,
        left: 24,
        right: 24,
      ),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: context.accentSubtle,
                child: Icon(
                  widget.isAi ? Icons.smart_toy_rounded : Icons.person_rounded,
                  color: context.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isAi
                    ? 'Your AI assistant is ready to help'
                    : 'Start a conversation',
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: starters
                    .map((s) => _StarterChip(label: s, onTap: _sendStarter))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBubbleRow(ChatMessage msg, _BubblePosition pos) {
    final isUser = msg.isUser;
    final radius = _bubbleRadius(isUser, pos);
    final bool showAvatar = !isUser && pos == _BubblePosition.last;
    final bool isLastInGroup =
        pos == _BubblePosition.last || pos == _BubblePosition.solo;

    return GestureDetector(
      onLongPress: () => _onMessageLongPress(msg),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            SizedBox(
              width: 36,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: context.accentSubtle,
                      child: Icon(
                        widget.isAi
                            ? Icons.smart_toy_rounded
                            : Icons.person_rounded,
                        color: context.accent,
                        size: 14,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          if (!isUser) const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? context.accent : context.bgSurface,
                borderRadius: radius,
                border: (!isUser && !context.isDark)
                    ? Border.all(color: context.borderSubtle)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MarkdownBody(
                    data: msg.text,
                    selectable: false,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser
                            ? SlateTokens.textOnAccent
                            : context.textPrimary,
                        fontSize: 15,
                        height: 1.45,
                      ),
                      strong: TextStyle(
                        color: isUser
                            ? SlateTokens.textOnAccent
                            : context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                      em: TextStyle(
                        color: isUser
                            ? SlateTokens.textOnAccent
                            : context.textPrimary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                      ),
                      del: TextStyle(
                        color: isUser
                            ? SlateTokens.textOnAccent
                            : context.textPrimary,
                        fontSize: 15,
                        decoration: TextDecoration.lineThrough,
                        height: 1.45,
                      ),
                      code: TextStyle(
                        color: isUser ? Colors.white : context.accent,
                        backgroundColor:
                            isUser ? Colors.white24 : context.accentSubtle,
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.black26
                            : context.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: isUser
                            ? null
                            : Border.all(color: context.borderSubtle),
                      ),
                      codeblockPadding: const EdgeInsets.all(8),
                      listBullet: TextStyle(
                        color: isUser
                            ? SlateTokens.textOnAccent
                            : context.textPrimary,
                        fontSize: 15,
                      ),
                      blockquote: TextStyle(
                        color: isUser ? Colors.white70 : context.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 14.5,
                      ),
                      a: TextStyle(
                        color: isUser ? Colors.white : context.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (isLastInGroup) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.isBookmarked) ...[
                          Icon(
                            Icons.bookmark_rounded,
                            size: 12,
                            color: isUser ? Colors.white70 : context.accent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          msg.formattedTime,
                          style: TextStyle(
                            color: isUser ? Colors.white60 : context.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.02,
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.status == MessageStatus.sending
                                ? Icons.schedule_rounded
                                : Icons.done_all_rounded,
                            size: 13,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 2),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 58, bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: context.isDark
                  ? null
                  : Border.all(color: context.borderSubtle),
            ),
            child: _TypingDots(color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, maxHeight: 156),
          decoration: BoxDecoration(
            color: context.bgElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(
                      color: context.textMuted,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _SendButton(
                  onTap: _handleSend,
                  color: _hasText
                      ? context.accent
                      : context.accent.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollDownPill() {
    return GestureDetector(
      onTap: () => _scrollToBottom(force: true),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New messages',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: context.accent, size: 18),
          ],
        ),
      ),
    );
  }
}

enum _BubblePosition { solo, first, middle, last }

class _MessageActionSheet extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  const _MessageActionSheet({
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
            leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
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
            leading: Icon(Icons.delete_outline_rounded, color: context.statusDanger),
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

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _SendButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_upward_rounded,
            color: Colors.white, size: 18),
      ),
    );
  }
}

class _StarterChip extends StatelessWidget {
  final String label;
  final void Function(String) onTap;

  const _StarterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.accentSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.accent.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: context.accent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final scale = 0.6 + 0.6 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
