enum MessageStatus { sending, sent, delivered, read }

enum AttachmentType { none, image, document, location }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String senderName;
  final DateTime timestamp;
  MessageStatus status;
  bool isBookmarked;
  final AttachmentType attachmentType;
  final String? attachmentName;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.senderName,
    required this.timestamp,
    this.status = MessageStatus.delivered,
    this.isBookmarked = false,
    this.attachmentType = AttachmentType.none,
    this.attachmentName,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'isBookmarked': isBookmarked,
      'attachmentType': attachmentType.name,
      'attachmentName': attachmentName,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? MessageIdGenerator().toString(),
      text: map['text'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      senderName: map['senderName'] as String? ?? '',
      timestamp: _parseDateTime(map['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.delivered,
      ),
      isBookmarked: map['isBookmarked'] as bool? ?? false,
      attachmentType: AttachmentType.values.firstWhere(
        (e) => e.name == map['attachmentType'],
        orElse: () => AttachmentType.none,
      ),
      attachmentName: map['attachmentName'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    try {
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}

class MessageIdGenerator {
  static int _counter = 0;
  @override
  String toString() => 'msg_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
