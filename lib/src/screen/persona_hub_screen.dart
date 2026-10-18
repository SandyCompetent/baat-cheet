import 'package:flutter/material.dart';
import '../../theme_data.dart';
import '../models/persona.dart';
import '../services/chat_service.dart';
import '../services/memory_service.dart';
import '../services/persona_service.dart';
import 'conversation_screen.dart';

class PersonaHubScreen extends StatefulWidget {
  const PersonaHubScreen({super.key});

  @override
  State<PersonaHubScreen> createState() => _PersonaHubScreenState();
}

class _PersonaHubScreenState extends State<PersonaHubScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'All',
    'Engineering',
    'Security',
    'Philosophy',
    'Creative',
    'Custom',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCreatePersonaDialog() {
    final nameCtrl = TextEditingController();
    final taglineCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    String category = 'Custom';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create New Persona',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Enter a persona name' : null,
                    decoration: InputDecoration(
                      hintText: 'Persona Name (e.g., Nova, Cipher)',
                      hintStyle: TextStyle(color: context.textMuted),
                      prefixIcon: Icon(Icons.smart_toy_outlined, color: context.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: taglineCtrl,
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Enter a short tagline' : null,
                    decoration: InputDecoration(
                      hintText: 'Tagline (e.g., Senior Security Specialist)',
                      hintStyle: TextStyle(color: context.textMuted),
                      prefixIcon: Icon(Icons.badge_outlined, color: context.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: context.bgSurface,
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: context.textMuted),
                      prefixIcon: Icon(Icons.category_outlined, color: context.accent),
                    ),
                    items: ['Custom', 'Engineering', 'Security', 'Philosophy', 'Creative']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: promptCtrl,
                    maxLines: 4,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    validator: (val) =>
                        (val == null || val.trim().length < 10)
                            ? 'System prompt must be at least 10 chars'
                            : null,
                    decoration: InputDecoration(
                      hintText:
                          'System Prompt / Instructions\n(e.g., You are an adversarial code reviewer...)',
                      hintStyle: TextStyle(color: context.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tagsCtrl,
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tags (comma separated, e.g. Dart, Clean Code)',
                      hintStyle: TextStyle(color: context.textMuted),
                      prefixIcon: Icon(Icons.tag_outlined, color: context.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: context.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final tags = tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  await PersonaService.instance.createCustomPersona(
                    name: nameCtrl.text.trim(),
                    tagline: taglineCtrl.text.trim(),
                    description: taglineCtrl.text.trim(),
                    systemPrompt: promptCtrl.text.trim(),
                    category: category,
                    tags: tags,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Create Persona'),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      appBar: AppBar(
        title: const Text('Persona Hub'),
        actions: [
          IconButton(
            tooltip: 'Create Persona',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openCreatePersonaDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Persona Showcase Banner
          ValueListenableBuilder<Persona>(
            valueListenable: PersonaService.instance.activePersonaNotifier,
            builder: (context, activePersona, _) {
              final rel = MemoryService.instance.getRelationshipState(activePersona.id);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.accent.withAlpha(80), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: context.accent.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: context.accentSubtle,
                      child: Text(
                        activePersona.name[0].toUpperCase(),
                        style: TextStyle(
                          color: context.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activePersona.name,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.statusOnline.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: context.statusOnline,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activePersona.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Tooltip(
                                message:
                                    'Trust increases as you chat. Higher trust unlocks more personalized responses.',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: rel.trustLevel >= 8
                                        ? Colors.amber.withAlpha(30)
                                        : context.accentSubtle,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: rel.trustLevel >= 8
                                          ? Colors.amber.withAlpha(80)
                                          : context.accent.withAlpha(50),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.handshake_outlined,
                                        size: 14,
                                        color: rel.trustLevel >= 8
                                            ? Colors.amber.shade400
                                            : context.accent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Trust: ${rel.trustLevel}/10',
                                        style: TextStyle(
                                          color: rel.trustLevel >= 8
                                              ? Colors.amber.shade400
                                              : context.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.bgElevated,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                child: Text(
                                  'Mood: ${rel.mood}',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Chat with ${activePersona.name}',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        minimumSize: const Size(38, 38),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      onPressed: () async {
                        final conv = await ChatService.instance
                            .startPersonaConversation(activePersona);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                conversationId: conv.id,
                                title: conv.title,
                                isAi: true,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: context.accentSubtle,
                    checkmarkColor: context.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? context.accent : context.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Personas List
          Expanded(
            child: ValueListenableBuilder<List<Persona>>(
              valueListenable: PersonaService.instance.personasNotifier,
              builder: (context, allPersonas, _) {
                final filtered = allPersonas.where((p) {
                  if (_selectedCategory == 'All') return true;
                  if (_selectedCategory == 'Custom') return !p.isCurated;
                  return p.category.toLowerCase() == _selectedCategory.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No personas in "$_selectedCategory"',
                      style: TextStyle(color: context.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final persona = filtered[idx];
                    final rel = MemoryService.instance.getRelationshipState(persona.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: context.bgSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: context.borderSubtle),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: context.bgElevated,
                                  child: Text(
                                    persona.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            persona.name,
                                            style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: persona.isCurated
                                                  ? context.accentSubtle
                                                  : context.bgElevated,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              persona.isCurated ? 'BUILT-IN' : 'CUSTOM',
                                              style: TextStyle(
                                                color: persona.isCurated
                                                    ? context.accent
                                                    : context.textMuted,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        persona.tagline,
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ValueListenableBuilder<Persona>(
                                  valueListenable: PersonaService.instance.activePersonaNotifier,
                                  builder: (context, activeP, _) {
                                    final isActive = activeP.id == persona.id;
                                    if (isActive) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.statusOnline.withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                              color: context.statusOnline.withAlpha(80)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle,
                                                size: 12, color: context.statusOnline),
                                            const SizedBox(width: 4),
                                            Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                color: context.statusOnline,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        side: BorderSide(color: context.borderSubtle),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => PersonaService.instance
                                          .setActivePersona(persona.id),
                                      child: Text(
                                        'Set Active',
                                        style: TextStyle(
                                          color: context.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!persona.isCurated) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(Icons.delete_outline,
                                        size: 18, color: context.statusDanger),
                                    onPressed: () => PersonaService.instance
                                        .deleteCustomPersona(persona.id),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              persona.description,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: persona.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: context.bgElevated,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: context.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Tooltip(
                                        message:
                                            'Trust increases as you chat. Higher trust unlocks more personalized responses.',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: rel.trustLevel >= 8
                                                ? Colors.amber.withAlpha(30)
                                                : context.accentSubtle,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: rel.trustLevel >= 8
                                                  ? Colors.amber.withAlpha(80)
                                                  : context.accent.withAlpha(50),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.handshake_outlined,
                                                size: 14,
                                                color: rel.trustLevel >= 8
                                                    ? Colors.amber.shade400
                                                    : context.accent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Trust: ${rel.trustLevel}/10',
                                                style: TextStyle(
                                                  color: rel.trustLevel >= 8
                                                      ? Colors.amber.shade400
                                                      : context.accent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: context.bgElevated,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        child: Text(
                                          'Mood: ${rel.mood}',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: context.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(10),
                                    minimumSize: const Size(38, 38),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                                      size: 18),
                                  tooltip: 'Chat with ${persona.name}',
                                  onPressed: () async {
                                    final conv = await ChatService.instance
                                        .startPersonaConversation(persona);
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ConversationScreen(
                                            conversationId: conv.id,
                                            title: conv.title,
                                            isAi: true,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
