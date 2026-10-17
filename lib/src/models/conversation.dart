class Conversation {
  final String id;
  final String title;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool isAi;
  final bool isGroup;
  final String? avatarUrl;

  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.isAi = false,
    this.isGroup = false,
    this.avatarUrl,
  });

  Conversation copyWith({
    String? id,
    String? title,
    String? lastMessage,
    String? lastTime,
    int? unreadCount,
    bool? isAi,
    bool? isGroup,
    String? avatarUrl,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isAi: isAi ?? this.isAi,
      isGroup: isGroup ?? this.isGroup,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
