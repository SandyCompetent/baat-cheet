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
    test('Initializes with empty state and no mock data', () {
      final service = GroupService.instance;
      expect(service.groupsNotifier.value, isNotNull);
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

    test(
        'toggleJoinGroup toggles membership and increments/decrements member count',
        () async {
      final service = GroupService.instance;
      final newGroup = await service.createGroup(
        name: 'Test Group',
        description: 'Testing join toggle',
      );

      final initialJoined = newGroup.isJoined;
      final initialMembers = newGroup.memberCount;

      await service.toggleJoinGroup(newGroup.id);

      final updatedGroup =
          service.groupsNotifier.value.firstWhere((g) => g.id == newGroup.id);
      expect(updatedGroup.isJoined, !initialJoined);
      expect(
        updatedGroup.memberCount,
        initialJoined ? initialMembers - 1 : initialMembers + 1,
      );
    });
  });
}
