import 'package:chatbud/src/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conversation Model Tests', () {
    test('Constructor initializes properties correctly', () {
      const conv = Conversation(
        id: 'conv_101',
        title: 'Tech Support',
        lastMessage: 'How can I help?',
        lastTime: '11:20',
        unreadCount: 3,
        isAi: true,
        isGroup: false,
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(conv.id, 'conv_101');
      expect(conv.title, 'Tech Support');
      expect(conv.lastMessage, 'How can I help?');
      expect(conv.lastTime, '11:20');
      expect(conv.unreadCount, 3);
      expect(conv.isAi, true);
      expect(conv.isGroup, false);
      expect(conv.avatarUrl, 'https://example.com/avatar.png');
    });

    test('copyWith updates target attributes while retaining existing ones', () {
      const original = Conversation(
        id: 'conv_102',
        title: 'Project Chat',
        lastMessage: 'Let us meet tomorrow',
        lastTime: '09:00',
        unreadCount: 1,
        isAi: false,
        isGroup: true,
      );

      final updated = original.copyWith(
        lastMessage: 'Meeting rescheduled to 2 PM',
        unreadCount: 0,
      );

      expect(updated.id, 'conv_102');
      expect(updated.title, 'Project Chat');
      expect(updated.lastMessage, 'Meeting rescheduled to 2 PM');
      expect(updated.lastTime, '09:00');
      expect(updated.unreadCount, 0);
      expect(updated.isAi, false);
      expect(updated.isGroup, true);
    });

    test('supports personaId and personaIds with serialization', () {
      const conv = Conversation(
        id: 'conv_persona_1',
        title: 'Athena Chat',
        lastMessage: 'Let us review the architecture.',
        lastTime: '12:00',
        isAi: true,
        personaId: 'athena',
        personaIds: ['athena', 'cipher'],
      );

      expect(conv.personaId, 'athena');
      expect(conv.personaIds, ['athena', 'cipher']);

      final map = conv.toMap();
      expect(map['personaId'], 'athena');
      expect(map['personaIds'], ['athena', 'cipher']);

      final restored = Conversation.fromMap(map);
      expect(restored.personaId, 'athena');
      expect(restored.personaIds, ['athena', 'cipher']);
      expect(restored.title, 'Athena Chat');
      expect(restored.isAi, true);
    });
  });
}
