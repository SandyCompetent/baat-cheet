import 'package:chatbud/src/core/avatar_helper.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';

/// A single row in the conversation list — the "sidebar chat row" component.
///
/// Renders a 68px-tall InkWell row with:
///   • 36px avatar with a 10px online dot on the bottom-right for AI entries
///   • Bold name (text-primary, 15px Semi-Bold)
///   • Single-line truncated preview (text-secondary, 14px)
///   • Timestamp (text-muted, 11px, +0.02em letter-spacing)
///   • Unread badge (accent-subtle bg + accent text) when [unreadCount] > 0
class MessageItem extends StatelessWidget {
  final String imgRef;
  final String txtPersonName;
  final String txtMessage;
  final String txtTime;
  final VoidCallback? onTap;
  final bool isAi;
  final int unreadCount;

  const MessageItem({
    super.key,
    required this.imgRef,
    required this.txtPersonName,
    required this.txtMessage,
    required this.txtTime,
    this.onTap,
    this.isAi = false,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // ── Avatar ──
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isAi
                      ? context.accentSubtle
                      : getAvatarColor(txtPersonName),
                  child: isAi
                      ? Icon(Icons.smart_toy_rounded,
                          color: context.accent, size: 26)
                      : Text(
                          getInitials(txtPersonName, ''),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                ),
                // Online presence dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isAi ? context.statusOnline : context.bgElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.bgCanvas,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Name + preview ──
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                txtPersonName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: context.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAi) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.accentSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: context.accent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Timestamp
                      Text(
                        txtTime,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? context.accent
                              : context.textMuted,
                          fontSize: 11,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: 0.02,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          txtMessage,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ── Unread badge ──
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: context.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
