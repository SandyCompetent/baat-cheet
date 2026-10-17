class GroupChat {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String lastActive;
  final bool isJoined;

  const GroupChat({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.lastActive,
    this.isJoined = false,
  });

  GroupChat copyWith({
    String? id,
    String? name,
    String? description,
    int? memberCount,
    String? lastActive,
    bool? isJoined,
  }) {
    return GroupChat(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      lastActive: lastActive ?? this.lastActive,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'memberCount': memberCount,
        'lastActive': lastActive,
        'isJoined': isJoined,
      };

  factory GroupChat.fromMap(Map<String, dynamic> map) => GroupChat(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        memberCount: (map['memberCount'] as num?)?.toInt() ?? 1,
        lastActive: map['lastActive'] as String? ?? 'Just now',
        isJoined: map['isJoined'] as bool? ?? false,
      );
}
