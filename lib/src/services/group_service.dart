import 'package:flutter/foundation.dart';
import '../core/storage_service.dart';
import '../models/group_chat.dart';

/// Service managing community and user-created group channels.
class GroupService {
  static final GroupService instance = GroupService._internal();
  GroupService._internal() {
    _loadGroups();
  }

  final ValueNotifier<List<GroupChat>> groupsNotifier =
      ValueNotifier<List<GroupChat>>([]);

  void _loadGroups() {
    final defaultGroups = [
      const GroupChat(
        id: 'group_flutter',
        name: 'Flutter Global Community',
        description: 'Discussions on Flutter architecture, state management, and animations.',
        memberCount: 2480,
        lastActive: '5m ago',
        isJoined: true,
      ),
      const GroupChat(
        id: 'group_ai',
        name: 'AI & LLM Builders',
        description: 'Agentic workflows, prompt engineering, and Gemini integrations.',
        memberCount: 1850,
        lastActive: '12m ago',
        isJoined: true,
      ),
      const GroupChat(
        id: 'group_design',
        name: 'Slate Design System',
        description: 'Minimalist UI design tokens, accessibility, and micro-interactions.',
        memberCount: 920,
        lastActive: '1h ago',
        isJoined: false,
      ),
    ];

    final customSaved = StorageService.getSavedGroups();
    final customGroups = customSaved.map((m) => GroupChat.fromMap(m)).toList();

    groupsNotifier.value = [...defaultGroups, ...customGroups];
  }

  Future<GroupChat> createGroup({
    required String name,
    required String description,
  }) async {
    final newGroup = GroupChat(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      memberCount: 1,
      lastActive: 'Just now',
      isJoined: true,
    );

    final current = List<GroupChat>.from(groupsNotifier.value);
    current.insert(0, newGroup);
    groupsNotifier.value = current;

    // Save custom groups
    final customOnly = current.where((g) => g.id.startsWith('grp_')).toList();
    await StorageService.saveGroups(customOnly.map((g) => g.toMap()).toList());

    return newGroup;
  }

  void toggleJoinGroup(String groupId) {
    final current = List<GroupChat>.from(groupsNotifier.value);
    final idx = current.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final grp = current[idx];
      current[idx] = grp.copyWith(
        isJoined: !grp.isJoined,
        memberCount: grp.isJoined ? grp.memberCount - 1 : grp.memberCount + 1,
      );
      groupsNotifier.value = current;
    }
  }
}
