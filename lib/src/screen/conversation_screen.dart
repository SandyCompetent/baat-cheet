import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../theme_data.dart';
import '../core/app_state.dart';
import '../core/constants.dart';
import '../core/service_locator.dart';
import '../models/chat_message.dart';
import '../models/persona.dart';
import '../services/chat_service.dart';
import '../services/persona_service.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_glass_header.dart';
import '../widgets/exeter_campus_sheet.dart';
import '../widgets/message_action_sheet.dart';
import 'conversation/conversation_suggestions.dart';
import 'conversation/transcript_exporter.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final bool isAi;

  const ConversationScreen({
    super.key,
    this.conversationId = AppConstants.aiAssistantId,
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
        service<ChatService>().getMessagesNotifier(widget.conversationId);
    service<ChatService>().markAsRead(widget.conversationId);

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
    service<ChatService>()
        .setTypingStatus(widget.conversationId, uid, isTyping);
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

    service<ChatService>().sendMessage(
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
      builder: (ctx) => MessageActionSheet(
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
          service<ChatService>().toggleBookmark(msg);
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
          service<ChatService>().deleteMessage(widget.conversationId, msg.id);
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
                            title:
                                Text(r, style: const TextStyle(fontSize: 13)),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.statusDanger),
              onPressed: () {
                service<ChatService>().reportContent(
                  reportedUserId: msg.senderName,
                  messageId: msg.id,
                  reason: selectedReason,
                  messageText: msg.text,
                  reporterId: AppState.instance.firebaseUser?.uid,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Report submitted. Thank you for keeping ChatBud safe.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit Report',
                  style: TextStyle(color: Colors.white)),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: context.statusDanger),
            onPressed: () {
              service<ChatService>().blockUser(senderName);
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.title),
        content: Text(
          widget.isAi
              ? 'ChatBud AI Assistant answers any question or drafts messages in real time.'
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

  Persona? _resolveActivePersona() {
    if (widget.conversationId.startsWith('ai_persona_')) {
      final personaId = widget.conversationId.replaceFirst('ai_persona_', '');
      return service<PersonaService>().getPersonaById(personaId);
    }
    return service<PersonaService>().activePersonaNotifier.value;
  }

  List<String> get _starterPrompts {
    if (!widget.isAi) {
      return const ['Say hello 👋', 'How are you doing?', 'Let\'s catch up!'];
    }
    final persona = _resolveActivePersona();
    if (persona != null && persona.starterPrompts.isNotEmpty) {
      return persona.starterPrompts;
    }
    return const [
      'Say hello 👋',
      'Help me draft a message',
      'What can you help me with?',
    ];
  }

  void _showExportDialog() {
    final messages = _messagesNotifier.value;
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No messages to export yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: context.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Export Conversation Transcript',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Copy as Clean Plain Text'),
                subtitle:
                    const Text('Great for pasting into Slack, Email, or Docs'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyTranscript(asMarkdown: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text('Copy as Formatted Markdown'),
                subtitle:
                    const Text('Great for Notion, GitHub, or documentation'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyTranscript(asMarkdown: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyTranscript({required bool asMarkdown}) {
    final messages = _messagesNotifier.value;
    final transcript = TranscriptExporter.build(
      messages: messages,
      title: widget.title,
      asMarkdown: asMarkdown,
    );
    Clipboard.setData(ClipboardData(text: transcript));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asMarkdown
                ? 'Markdown transcript copied to clipboard!'
                : 'Plain text transcript copied to clipboard!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSuggestionTap(String text) {
    _textCtrl.text = text;
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  List<String> get _suggestedReplies => ConversationSuggestions.forHistory(
        messages: _messagesNotifier.value,
        starterPrompts: _starterPrompts,
      );

  Widget _buildSuggestionsBar(List<ChatMessage> messages) {
    if (messages.isEmpty) return const SizedBox.shrink();

    final suggestions = _suggestedReplies;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final prompt = suggestions[i];
          return ActionChip(
            backgroundColor: context.bgElevated,
            side: BorderSide(color: context.borderSubtle),
            avatar: Icon(Icons.auto_awesome_rounded,
                size: 14, color: context.accent),
            label: Text(
              prompt,
              style: TextStyle(
                color: context.accent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _onSuggestionTap(prompt),
          );
        },
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
      appBar: ChatGlassHeader(
        title: widget.title,
        isAi: widget.isAi,
        isTyping: _isTyping,
        onInfoPressed: _showInfoDialog,
        onExportPressed: _showExportDialog,
        onCampusLivePressed:
            widget.isAi && _resolveActivePersona()?.id == 'exeter'
                ? () => ExeterCampusSheet.show(context)
                : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: _messagesNotifier,
                  builder: (context, messages, _) {
                    return Column(
                      children: [
                        Expanded(child: _buildMessageFeed(messages)),
                        if (widget.isAi && messages.isNotEmpty)
                          _buildSuggestionsBar(messages),
                      ],
                    );
                  },
                ),
              ),
              StreamBuilder<bool>(
                stream: service<ChatService>()
                    .listenTypingStatus(widget.conversationId, currentUid),
                builder: (context, snapshot) {
                  final typing = _isTyping || (snapshot.data == true);
                  if (typing) {
                    return _buildTypingIndicator();
                  }
                  return const SizedBox.shrink();
                },
              ),
              ChatComposer(
                textCtrl: _textCtrl,
                hasText: _hasText,
                onSend: _handleSend,
              ),
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
        final topGap =
            (i > 0 && messages[i - 1].isUser != msg.isUser) ? 16.0 : 4.0;
        return Padding(
          padding: EdgeInsets.only(top: topGap),
          child: _buildBubbleRow(msg, pos),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final starters = _starterPrompts;

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                        color: isUser ? Colors.black26 : context.bgElevated,
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
