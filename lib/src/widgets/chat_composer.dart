import 'package:flutter/material.dart';
import '../../theme_data.dart';

class ChatComposer extends StatelessWidget {
  final TextEditingController textCtrl;
  final bool hasText;
  final VoidCallback onSend;

  const ChatComposer({
    super.key,
    required this.textCtrl,
    required this.hasText,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
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
                  controller: textCtrl,
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
                  onTap: onSend,
                  color: hasText
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
