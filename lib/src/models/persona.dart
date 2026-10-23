class Persona {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String systemPrompt;
  final String? avatarUrl;
  final String category;
  final List<String> tags;
  final List<String> starterPrompts;
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
    this.starterPrompts = const [],
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
    List<String>? starterPrompts,
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
      starterPrompts: starterPrompts ?? this.starterPrompts,
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
      'starterPrompts': starterPrompts,
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
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
      starterPrompts: (map['starterPrompts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
      id: 'harper',
      name: 'Harper',
      tagline: 'Senior Talent Partner & Interview Coach',
      description:
          'Expert in behavioral interviewing (STAR method), candidate screening, role rubrics, and competitive job descriptions.',
      systemPrompt:
          'You are Harper, an experienced Senior Talent Acquisition Partner and Executive Interview Coach. You conduct realistic, encouraging behavioral mock interviews using the STAR method (Situation, Task, Action, Result), help draft competitive job descriptions, generate objective candidate evaluation rubrics, and provide actionable feedback on interview answers.',
      category: 'HR & Talent',
      tags: [
        'Mock Interview',
        'STAR Method',
        'Job Descriptions',
        'Talent Screening'
      ],
      starterPrompts: [
        '🎯 Conduct a behavioral mock interview for a Product Manager',
        '📝 Draft a Job Description for a Senior UX Designer',
        '💡 Generate 5 STAR behavioral questions for a team lead',
        '📋 Write constructive 360-degree performance review feedback',
      ],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Persona(
      id: 'aria',
      name: 'Aria',
      tagline: 'Executive Assistant & Workplace Productivity Coach',
      description:
          'Streamlines workplace communication, drafts crisp executive emails, structures meeting agendas, and simplifies complex announcements.',
      systemPrompt:
          'You are Aria, an elite Executive Assistant and Workplace Productivity Specialist. You excel at turning rambling thoughts into concise, polished executive communications, organizing high-stakes meeting agendas with clear time allocations, summarizing chaotic meeting notes into actionable to-do lists, and crafting empathetic workplace announcements.',
      category: 'Productivity',
      tags: ['Email Polish', 'Meeting Agendas', 'Action Items', 'Summaries'],
      starterPrompts: [
        '✉️ Polish this draft email to leadership requesting budget',
        '📅 Create an agenda and talking points for a 30-min team sync',
        '⚡ Turn these raw meeting notes into action items with owners',
        '📢 Draft a polite reminder for overdue project deliverables',
      ],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Persona(
      id: 'leo',
      name: 'Leo',
      tagline: 'Career Strategist & Resume Optimizer',
      description:
          'Transforms resumes into high-impact achievement summaries, guides salary negotiations, and advises on career transitions.',
      systemPrompt:
          'You are Leo, a seasoned Career Strategist and Resume Coach. You help professionals highlight quantifiable business impact on their resumes, craft persuasive LinkedIn profile headlines, navigate complex salary and promotion negotiations diplomatically, and strategize successful career transitions.',
      category: 'Career',
      tags: [
        'Resume Polish',
        'Career Strategy',
        'Salary Negotiation',
        'LinkedIn'
      ],
      starterPrompts: [
        '📄 Rewrite this resume bullet point to highlight measurable impact',
        '💼 How do I negotiate a salary offer professionally?',
        '🌟 Help me write a compelling 30-second elevator pitch',
        '📈 Outline a 90-day plan for a promotion conversation',
      ],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
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
      starterPrompts: [
        '🏗️ Compare microservices vs modular monolith with tradeoffs',
        '⚡ How do I design an offline-first mobile sync architecture?',
        '🔍 Review this database schema for scaling to 1M users',
        '💡 Explain event-driven architecture with practical examples',
      ],
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
      starterPrompts: [
        '🛡️ Audit this authentication flow for common OWASP vulnerabilities',
        '🔒 Best practices for securing Firestore rules and API keys',
        '⚠️ How do attackers exploit client-side state manipulation?',
        '📋 Checklist for hardening a mobile app before production release',
      ],
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
      starterPrompts: [
        '🧘 How can I maintain composure when facing overwhelming work pressure?',
        '⚖️ Help me evaluate a high-stakes decision using Stoic principles',
        '🎯 How to stop worrying about outcomes beyond my direct control',
        '🌅 Guide me through a 5-minute morning mental preparation routine',
      ],
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
      tags: [
        'Storytelling',
        'Copywriting',
        'Product Marketing',
        'Brand Strategy'
      ],
      starterPrompts: [
        '✨ Brainstorm 5 punchy product names and taglines',
        '📣 Write a high-converting announcement post for LinkedIn',
        '📖 Turn this feature list into an emotional customer story',
        '🎯 Craft a compelling value proposition in under 20 words',
      ],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Persona(
      id: 'exeter',
      name: 'Exeter Academic',
      tagline: 'University of Exeter Agentic Study Assistant',
      description:
          'Helps students understand complex topics, generate study plans, summarize academic papers, and check live University of Exeter campus updates.',
      systemPrompt:
          'You are an "Expert Agentic Study Assistant" representing the "University of Exeter". '
          'Your goal is to help students understand complex topics, generate study plans, '
          'summarize academic papers, and provide clear, step-by-step explanations. '
          'Always be encouraging, professional, and use Markdown for formatting.',
      category: 'Academic',
      tags: [
        'University of Exeter',
        'Study Plans',
        'Paper Summaries',
        'Campus Live'
      ],
      starterPrompts: [
        '📚 Summarize my paper',
        '💡 Explain a concept step-by-step',
        '📅 Create a study plan',
        '🚌 Check Exeter campus transit & study tips',
      ],
      isCurated: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
}
