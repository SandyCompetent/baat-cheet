import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme_data.dart';
import '../models/chat_message.dart';

class AttachmentOption {
  final String title;
  final IconData icon;
  final AttachmentType type;
  final Color color;

  const AttachmentOption({
    required this.title,
    required this.icon,
    required this.type,
    required this.color,
  });
}

class AttachmentSheet extends StatelessWidget {
  final Function(AttachmentType type, String name) onSelect;

  const AttachmentSheet({super.key, required this.onSelect});

  static Future<void> show(
    BuildContext context, {
    required Function(AttachmentType type, String name) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      AttachmentOption(
        title: 'Photos & Videos',
        icon: Icons.photo_library_outlined,
        type: AttachmentType.image,
        color: context.accent,
      ),
      AttachmentOption(
        title: 'Camera',
        icon: Icons.camera_alt_outlined,
        type: AttachmentType.image,
        color: const Color(0xFF0EA5E9),
      ),
      AttachmentOption(
        title: 'Document',
        icon: Icons.insert_drive_file_outlined,
        type: AttachmentType.document,
        color: const Color(0xFF8B5CF6),
      ),
      AttachmentOption(
        title: 'Location',
        icon: Icons.location_on_outlined,
        type: AttachmentType.location,
        color: context.statusOnline,
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: context.borderSubtle)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Content',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: context.textMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: options.map((opt) {
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onSelect(opt.type, opt.title);
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(opt.icon, color: opt.color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt.title,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
