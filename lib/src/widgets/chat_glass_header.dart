import 'dart:ui';
import 'package:chatbud/src/core/avatar_helper.dart';
import 'package:flutter/material.dart';
import '../../theme_data.dart';

class ChatGlassHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isAi;
  final bool isTyping;
  final VoidCallback onInfoPressed;
  final VoidCallback? onExportPressed;

  const ChatGlassHeader({
    super.key,
    required this.title,
    required this.isAi,
    required this.isTyping,
    required this.onInfoPressed,
    this.onExportPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
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
                        backgroundColor:
                            isAi ? context.accentSubtle : getAvatarColor(title),
                        child: isAi
                            ? Icon(Icons.smart_toy_rounded,
                                color: context.accent, size: 20)
                            : Text(
                                getInitials(title, ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
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
                          title,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isTyping
                              ? 'Typing...'
                              : (isAi ? 'Online • AI Assistant' : 'Online'),
                          style: TextStyle(
                            color: isTyping
                                ? context.accent
                                : context.statusOnline,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onExportPressed != null)
                    IconButton(
                      tooltip: 'Export Transcript',
                      icon: Icon(
                        Icons.share_outlined,
                        color: context.accent,
                        size: 20,
                      ),
                      onPressed: onExportPressed,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: context.accent,
                      size: 22,
                    ),
                    onPressed: onInfoPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
