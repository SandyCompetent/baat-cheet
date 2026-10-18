class UserMemory {
  final String id;
  final String userId;
  final String? personaId;
  final String fact;
  final String category;
  final double confidence;
  final List<double>? embedding;
  final DateTime createdAt;
  final DateTime lastRecalledAt;

  const UserMemory({
    required this.id,
    required this.userId,
    this.personaId,
    required this.fact,
    this.category = 'general',
    this.confidence = 1.0,
    this.embedding,
    required this.createdAt,
    required this.lastRecalledAt,
  });

  UserMemory copyWith({
    String? id,
    String? userId,
    String? personaId,
    String? fact,
    String? category,
    double? confidence,
    List<double>? embedding,
    DateTime? createdAt,
    DateTime? lastRecalledAt,
  }) {
    return UserMemory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personaId: personaId ?? this.personaId,
      fact: fact ?? this.fact,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      lastRecalledAt: lastRecalledAt ?? this.lastRecalledAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'personaId': personaId,
      'fact': fact,
      'category': category,
      'confidence': confidence,
      if (embedding != null) 'embedding': embedding,
      'createdAt': createdAt.toIso8601String(),
      'lastRecalledAt': lastRecalledAt.toIso8601String(),
    };
  }

  factory UserMemory.fromMap(Map<String, dynamic> map) {
    return UserMemory(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? 'guest',
      personaId: map['personaId'] as String?,
      fact: map['fact'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      embedding: (map['embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastRecalledAt: map['lastRecalledAt'] != null
          ? DateTime.tryParse(map['lastRecalledAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}
