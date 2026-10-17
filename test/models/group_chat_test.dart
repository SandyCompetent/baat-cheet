import 'package:chatbud/src/models/group_chat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupChat Model Tests', () {
    test('Constructor creates GroupChat instance correctly', () {
      const group = GroupChat(
        id: 'grp_1',
        name: 'Flutter Developers',
        description: 'App development channel',
        memberCount: 150,
        lastActive: '5m ago',
        isJoined: true,
      );

      expect(group.id, 'grp_1');
      expect(group.name, 'Flutter Developers');
      expect(group.description, 'App development channel');
      expect(group.memberCount, 150);
      expect(group.lastActive, '5m ago');
      expect(group.isJoined, true);
    });

    test('copyWith updates specified fields', () {
      const group = GroupChat(
        id: 'grp_2',
        name: 'Design Team',
        description: 'UI/UX discussions',
        memberCount: 12,
        lastActive: '1h ago',
        isJoined: false,
      );

      final updated = group.copyWith(
        memberCount: 13,
        isJoined: true,
        lastActive: 'Just now',
      );

      expect(updated.id, 'grp_2');
      expect(updated.name, 'Design Team');
      expect(updated.memberCount, 13);
      expect(updated.isJoined, true);
      expect(updated.lastActive, 'Just now');
    });

    test('toMap and fromMap serialization and deserialization', () {
      const group = GroupChat(
        id: 'grp_3',
        name: 'Gaming Hub',
        description: 'Weekend tournaments',
        memberCount: 42,
        lastActive: '10m ago',
        isJoined: true,
      );

      final map = group.toMap();
      expect(map['id'], 'grp_3');
      expect(map['name'], 'Gaming Hub');
      expect(map['description'], 'Weekend tournaments');
      expect(map['memberCount'], 42);
      expect(map['lastActive'], '10m ago');
      expect(map['isJoined'], true);

      final fromMap = GroupChat.fromMap(map);
      expect(fromMap.id, group.id);
      expect(fromMap.name, group.name);
      expect(fromMap.description, group.description);
      expect(fromMap.memberCount, group.memberCount);
      expect(fromMap.lastActive, group.lastActive);
      expect(fromMap.isJoined, group.isJoined);
    });

    test('fromMap provides defaults for null/optional fields', () {
      final map = <String, dynamic>{
        'id': 'grp_4',
        'name': 'Minimal Group',
        'description': 'Minimal info',
      };

      final group = GroupChat.fromMap(map);
      expect(group.id, 'grp_4');
      expect(group.memberCount, 1);
      expect(group.lastActive, 'Just now');
      expect(group.isJoined, false);
    });
  });
}
