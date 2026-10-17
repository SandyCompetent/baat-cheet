import 'package:flutter/material.dart';
import '../../theme_data.dart';
import '../models/persona.dart';
import '../models/user_memory.dart';
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

  void _showMemoryVaultSheet() {
    final factCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_outlined, color: context.accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Long-Term Memory Vault',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Facts and preferences remembered across all conversations. Retrieved dynamically via vector cosine similarity.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: factCtrl,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a new fact (e.g. "I work in Flutter")',
                      hintStyle: TextStyle(color: context.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (factCtrl.text.trim().isNotEmpty) {
                      await MemoryService.instance.addMemory(
                        fact: factCtrl.text.trim(),
                        category: 'manual',
                      );
                      factCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ValueListenableBuilder<List<UserMemory>>(
                valueListenable: MemoryService.instance.memoriesNotifier,
                builder: (context, memories, _) {
                  if (memories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No memories recorded yet.\nChat with personas to automatically record facts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textMuted, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: memories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final mem = memories[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.bgElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_border, size: 16, color: context.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mem.fact,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 16, color: context.statusDanger),
                              onPressed: () =>
                                  MemoryService.instance.deleteMemory(mem.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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
            tooltip: 'Memory Vault',
            icon: const Icon(Icons.psychology_outlined),
            onPressed: _showMemoryVaultSheet,
          ),
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Trust: ${rel.trustLevel}/10',
                                style: TextStyle(
                                  color: context.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Mood: ${rel.mood}',
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
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
                      child: const Text('Chat'),
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
                                if (!persona.isCurated)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 18, color: context.statusDanger),
                                    onPressed: () => PersonaService.instance
                                        .deleteCustomPersona(persona.id),
                                  ),
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
                                Row(
                                  children: [
                                    Icon(Icons.handshake_outlined,
                                        size: 14, color: context.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Trust: ${rel.trustLevel}/10 • Mood: ${rel.mood}',
                                      style: TextStyle(
                                        color: context.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => PersonaService.instance
                                          .setActivePersona(persona.id),
                                      child: const Text('Set Active'),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                      label: const Text('Chat'),
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
