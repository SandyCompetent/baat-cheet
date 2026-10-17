import 'package:flutter/material.dart';

class MessageItem extends StatelessWidget {
  final String imgRef;
  final String txtPersonName;
  final String txtMessage;
  final String txtTime;
  final VoidCallback? onTap;
  final bool isAi;

  const MessageItem({
    super.key,
    required this.imgRef,
    required this.txtPersonName,
    required this.txtMessage,
    required this.txtTime,
    this.onTap,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isAi
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  child: isAi
                      ? const Icon(Icons.smart_toy, color: Colors.redAccent, size: 28)
                      : Image.asset('assets/app_logo.png', height: 36, width: 36),
                ),
                if (isAi)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        txtPersonName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: isAi ? Colors.redAccent : Colors.black87,
                        ),
                      ),
                      if (isAi) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'AI Assistant',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    txtMessage,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              txtTime,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
