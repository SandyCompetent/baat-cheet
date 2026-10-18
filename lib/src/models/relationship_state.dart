class RelationshipState {
  final String personaId;
  final int trustLevel;
  final String mood;
  final int interactionCount;
  final DateTime lastInteraction;
  final String? notes;

  RelationshipState({
    required this.personaId,
    int trustLevel = 1,
    this.mood = 'Supportive',
    this.interactionCount = 0,
    required this.lastInteraction,
    this.notes,
  }) : trustLevel = trustLevel.clamp(1, 10);

  RelationshipState copyWith({
    String? personaId,
    int? trustLevel,
    String? mood,
    int? interactionCount,
    DateTime? lastInteraction,
    String? notes,
  }) {
    return RelationshipState(
      personaId: personaId ?? this.personaId,
      trustLevel: (trustLevel ?? this.trustLevel).clamp(1, 10),
      mood: mood ?? this.mood,
      interactionCount: interactionCount ?? this.interactionCount,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personaId': personaId,
      'trustLevel': trustLevel,
      'mood': mood,
      'interactionCount': interactionCount,
      'lastInteraction': lastInteraction.toIso8601String(),
      'notes': notes,
    };
  }

  factory RelationshipState.fromMap(Map<String, dynamic> map) {
    return RelationshipState(
      personaId: map['personaId'] as String? ?? '',
      trustLevel: ((map['trustLevel'] as num?)?.toInt() ?? 1).clamp(1, 10),
      mood: map['mood'] as String? ?? 'Supportive',
      interactionCount: (map['interactionCount'] as num?)?.toInt() ?? 0,
      lastInteraction: map['lastInteraction'] != null
          ? DateTime.tryParse(map['lastInteraction'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }
}
