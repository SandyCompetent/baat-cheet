import 'package:chatbud/src/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessage Model Tests', () {
    test('ChatMessage creates with default values', () {
      final now = DateTime(2026, 3, 30, 10, 15);
      final msg = ChatMessage(
        id: 'msg_1',
        text: 'Hello ChatBud',
        isUser: true,
        senderName: 'Alice',
        timestamp: now,
      );

      expect(msg.id, 'msg_1');
      expect(msg.text, 'Hello ChatBud');
      expect(msg.isUser, true);
      expect(msg.senderName, 'Alice');
      expect(msg.status, MessageStatus.delivered);
      expect(msg.isBookmarked, false);
      expect(msg.attachmentType, AttachmentType.none);
      expect(msg.attachmentName, null);
    });

    test('formattedTime returns HH:mm padded time string', () {
      final time1 = DateTime(2026, 1, 1, 9, 5);
      final msg1 = ChatMessage(
        id: 'msg_2',
        text: 'Test',
        isUser: false,
        senderName: 'Bob',
        timestamp: time1,
      );
      expect(msg1.formattedTime, '09:05');

      final time2 = DateTime(2026, 1, 1, 14, 30);
      final msg2 = ChatMessage(
        id: 'msg_3',
        text: 'Test',
        isUser: false,
        senderName: 'Bob',
        timestamp: time2,
      );
      expect(msg2.formattedTime, '14:30');
    });

    test('toMap and fromMap serialization and deserialization', () {
      final timestamp = DateTime(2026, 5, 20, 18, 45);
      final msg = ChatMessage(
        id: 'msg_serial_1',
        text: 'Attachment test',
        isUser: true,
        senderName: 'Charlie',
        timestamp: timestamp,
        status: MessageStatus.sent,
        isBookmarked: true,
        attachmentType: AttachmentType.image,
        attachmentName: 'photo.jpg',
      );

      final map = msg.toMap();
      expect(map['id'], 'msg_serial_1');
      expect(map['text'], 'Attachment test');
      expect(map['isUser'], true);
      expect(map['senderName'], 'Charlie');
      expect(map['status'], 'sent');
      expect(map['isBookmarked'], true);
      expect(map['attachmentType'], 'image');
      expect(map['attachmentName'], 'photo.jpg');

      final restored = ChatMessage.fromMap(map);
      expect(restored.id, msg.id);
      expect(restored.text, msg.text);
      expect(restored.isUser, msg.isUser);
      expect(restored.senderName, msg.senderName);
      expect(restored.status, MessageStatus.sent);
      expect(restored.isBookmarked, true);
      expect(restored.attachmentType, AttachmentType.image);
      expect(restored.attachmentName, 'photo.jpg');
    });

    test('fromMap handles missing/null map fields gracefully', () {
      final emptyMap = <String, dynamic>{};
      final restored = ChatMessage.fromMap(emptyMap);

      expect(restored.id.isNotEmpty, true);
      expect(restored.text, '');
      expect(restored.isUser, false);
      expect(restored.senderName, '');
      expect(restored.status, MessageStatus.delivered);
      expect(restored.isBookmarked, false);
      expect(restored.attachmentType, AttachmentType.none);
    });

    test('MessageIdGenerator generates unique string identifiers', () {
      final key1 = MessageIdGenerator().toString();
      final key2 = MessageIdGenerator().toString();

      expect(key1.startsWith('msg_'), true);
      expect(key2.startsWith('msg_'), true);
      expect(key1 != key2, true);
    });
  });
}
