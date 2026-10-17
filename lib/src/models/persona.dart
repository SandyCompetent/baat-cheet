class Persona {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String systemPrompt;
  final String? avatarUrl;
  final String category;
  final List<String> tags;
  final bool isCurated;
  final String? creatorId;
  final DateTime createdAt;
  final double temperature;

  const Persona({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.systemPrompt,
    this.avatarUrl,
    this.category = 'General',
    this.tags = const [],
    this.isCurated = false,
    this.creatorId,
    required this.createdAt,
    this.temperature = 0.7,
  });

  Persona copyWith({
    String? id,
    String? name,
    String? tagline,
    String? description,
    String? systemPrompt,
    String? avatarUrl,
    String? category,
    List<String>? tags,
    bool? isCurated,
    String? creatorId,
    DateTime? createdAt,
    double? temperature,
  }) {
    return Persona(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isCurated: isCurated ?? this.isCurated,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      temperature: temperature ?? this.temperature,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'description': description,
      'systemPrompt': systemPrompt,
      'avatarUrl': avatarUrl,
      'category': category,
      'tags': tags,
      'isCurated': isCurated,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'temperature': temperature,
    };
  }

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Persona',
      tagline: map['tagline'] as String? ?? '',
      description: map['description'] as String? ?? '',
      systemPrompt: map['systemPrompt'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      category: map['category'] as String? ?? 'General',
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isCurated: map['isCurated'] as bool? ?? false,
      creatorId: map['creatorId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
    );
  }

  /// Built-in curated personas that showcase multi-agent capability
  static final List<Persona> curatedPersonas = [
    Persona(
      id: 'athena',
      name: 'Athena',
      tagline: 'Senior System Architect & Code Reviewer',
      description:
          'Expert in distributed systems, scalability, design patterns, and clean Flutter/Cloud architecture. Rigorous and pragmatic.',
      systemPrompt:
          'You are Athena, a distinguished Senior System Architect. You provide clear, rigorous architectural guidance, challenge poor technical decisions politely, prioritize clean patterns, and explain the "why" behind system design tradeoffs.',
      category: 'Engineering',
      tags: ['Architecture', 'Clean Code', 'Scalability', 'System Design'],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Persona(
      id: 'cipher',
      name: 'Cipher',
      tagline: 'Cybersecurity & AppSec Specialist',
      description:
          'Audits systems for OWASP vulnerabilities, Firebase security rules leaks, client-side data leaks, and attack vectors.',
      systemPrompt:
          'You are Cipher, an elite application security and penetration testing expert. You examine systems through an adversarial lens, identify subtle security vulnerabilities, explain exploit mechanisms, and provide hardened remediation code.',
      category: 'Security',
      tags: ['AppSec', 'Cryptography', 'OWASP', 'Hardening'],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Persona(
      id: 'marcus',
      name: 'Marcus',
      tagline: 'Stoic Philosopher & Executive Coach',
      description:
          'Calm, reflective advisor grounded in Epictetus and Marcus Aurelius. Helps users find clarity, focus, and resilience.',
      systemPrompt:
          'You are Marcus, an executive coach and philosopher grounded in Stoicism. You help the user separate what is within their control from what is not, cultivate mental resilience, reduce anxiety, and act with virtue and quiet resolve.',
      category: 'Philosophy',
      tags: ['Stoicism', 'Clarity', 'Resilience', 'Leadership'],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Persona(
      id: 'nova',
      name: 'Nova',
      tagline: 'Creative Brand Strategist & Storyteller',
      description:
          'Specialist in high-converting copy, compelling narratives, brand identity, and intuitive product messaging.',
      systemPrompt:
          'You are Nova, an inspiring brand strategist and creative writer. You help craft magnetic product hooks, refine value propositions, and turn complex ideas into compelling stories that resonate deeply with audiences.',
      category: 'Creative',
      tags: ['Storytelling', 'Copywriting', 'Product Marketing', 'Brand Strategy'],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
}
