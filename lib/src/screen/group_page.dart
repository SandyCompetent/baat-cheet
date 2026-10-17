import 'package:chatbud/src/models/group_chat.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/services/group_service.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  void _openCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text(
          'Create New Group',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style: TextStyle(color: context.textPrimary, fontSize: 15),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter group name' : null,
                decoration: InputDecoration(
                  hintText: 'Group Name',
                  hintStyle: TextStyle(color: context.textMuted),
                  prefixIcon: Icon(Icons.group_outlined, color: context.accent),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                style: TextStyle(color: context.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Topic / Description (optional)',
                  hintStyle: TextStyle(color: context.textMuted),
                  prefixIcon:
                      Icon(Icons.description_outlined, color: context.accent),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final navigator = Navigator.of(context);
                final group = await GroupService.instance.createGroup(
                  name: nameCtrl.text,
                  description: descCtrl.text.isNotEmpty
                      ? descCtrl.text
                      : 'Community conversation',
                );
                if (!mounted) return;
                navigator.pop();
                // Open newly created group
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      conversationId: group.id,
                      title: group.name,
                      isAi: false,
                    ),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        title: Text(
          'Groups',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: context.accent),
            tooltip: 'Create Group',
            onPressed: _openCreateGroupDialog,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.borderSubtle),
        ),
      ),
      body: ValueListenableBuilder<List<GroupChat>>(
        valueListenable: GroupService.instance.groupsNotifier,
        builder: (context, groups, _) {
          if (groups.isEmpty) {
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
                    child: Icon(Icons.group_outlined,
                        color: context.accent, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Groups Yet',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create or join a group to get started',
                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _openCreateGroupDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create a Group'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(
                group: group,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        conversationId: group.id,
                        title: group.name,
                        isAi: false,
                      ),
                    ),
                  );
                },
                onToggleJoin: () {
                  HapticFeedback.lightImpact();
                  GroupService.instance.toggleJoinGroup(group.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupChat group;
  final VoidCallback onTap;
  final VoidCallback onToggleJoin;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.accentSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.groups_rounded,
                        color: context.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${group.memberCount} members',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ' • ${group.lastActive}',
                              style: TextStyle(
                                color: context.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onToggleJoin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          group.isJoined ? context.textSecondary : context.accent,
                      side: BorderSide(
                        color: group.isJoined
                            ? context.borderSubtle
                            : context.accent,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      group.isJoined ? 'Joined' : 'Join',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: group.isJoined
                            ? context.textSecondary
                            : context.accent,
                      ),
                    ),
                  ),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  group.description,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
