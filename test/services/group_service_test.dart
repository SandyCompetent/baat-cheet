import 'package:chatbud/src/core/storage_service.dart';
import 'package:chatbud/src/services/group_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('GroupService Tests', () {
    test('Initializes with default public groups', () {
      final service = GroupService.instance;
      final groups = service.groupsNotifier.value;

      expect(groups.isNotEmpty, true);
      expect(groups.any((g) => g.name.contains('Flutter Global Community')), true);
    });

    test('createGroup creates new group and appends to notifier', () async {
      final service = GroupService.instance;
      final countBefore = service.groupsNotifier.value.length;

      final newGroup = await service.createGroup(
        name: 'AI Innovators',
        description: 'Machine learning and LLM applications',
      );

      expect(service.groupsNotifier.value.length, countBefore + 1);
      expect(newGroup.name, 'AI Innovators');
      expect(newGroup.description, 'Machine learning and LLM applications');
      expect(newGroup.isJoined, true);
    });

    test('toggleJoinGroup toggles membership and increments/decrements member count', () {
      final service = GroupService.instance;
      final group = service.groupsNotifier.value.first;
      final initialJoined = group.isJoined;
      final initialMembers = group.memberCount;

      service.toggleJoinGroup(group.id);

      final updatedGroup =
          service.groupsNotifier.value.firstWhere((g) => g.id == group.id);
      expect(updatedGroup.isJoined, !initialJoined);
      expect(
        updatedGroup.memberCount,
        initialJoined ? initialMembers - 1 : initialMembers + 1,
      );
    });
  });
}
