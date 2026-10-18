import 'package:flutter/material.dart';
import '../../theme_data.dart';
import '../models/user_memory.dart';
import '../services/memory_service.dart';

/// Full-screen Long-Term Memory Vault tab in ChatBud.
///
/// Features:
/// - Displays all persistent user facts and preferences
/// - Explains the two-layer memory engine (short-term chat + long-term vector embeddings)
/// - Add manual facts & delete existing memories
/// - Real-time reactive updates via [MemoryService.memoriesNotifier]
class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  final TextEditingController _factCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _factCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAddFact() async {
    final text = _factCtrl.text.trim();
    if (text.isEmpty) return;

    _factCtrl.clear();
    await MemoryService.instance.addMemory(
      fact: text,
      category: 'manual',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Long-Term Memory: "$text"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        title: Text(
          'Long-Term Memory',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.borderSubtle),
        ),
      ),
      body: Column(
        children: [
          // Informational Architecture Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.accentSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.accent.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology_outlined, color: context.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Layer Memory Engine',
                        style: TextStyle(
                          color: context.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Personas retrieve your personal facts and preferences dynamically using vector embeddings. Facts can be extracted automatically from chats or added manually below.',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Add New Fact Input Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _factCtrl,
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    onSubmitted: (_) => _handleAddFact(),
                    decoration: InputDecoration(
                      hintText: 'Add a fact (e.g. "I work at Google", "Likes Dart")',
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                      prefixIcon: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: context.accent,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: context.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Save Fact',
                  onPressed: _handleAddFact,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search stored memories…',
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: context.bgElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Reactive Memory List Feed
          Expanded(
            child: ValueListenableBuilder<List<UserMemory>>(
              valueListenable: MemoryService.instance.memoriesNotifier,
              builder: (context, memories, _) {
                final filtered = memories.where((m) {
                  if (_searchQuery.isEmpty) return true;
                  return m.fact.toLowerCase().contains(_searchQuery) ||
                      m.category.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: context.accentSubtle,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.psychology_outlined,
                              color: context.accent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching memories found'
                                : 'No Memories Recorded Yet',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching for different keywords.'
                                : 'Chat with AI personas like Athena or Marcus. Facts and preferences you mention will be remembered here automatically!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final mem = filtered[idx];
                    final isManual = mem.category == 'manual';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isManual ? context.accentSubtle : context.bgElevated,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isManual ? Icons.edit_note_rounded : Icons.auto_awesome_rounded,
                              size: 16,
                              color: isManual ? context.accent : Colors.amber.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mem.fact,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.bgElevated,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isManual ? 'MANUAL' : 'AUTO-EXTRACTED',
                                        style: TextStyle(
                                          color: context.textMuted,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${mem.createdAt.day}/${mem.createdAt.month}/${mem.createdAt.year}',
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
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: context.statusDanger,
                            ),
                            tooltip: 'Delete Fact',
                            onPressed: () async {
                              await MemoryService.instance.deleteMemory(mem.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Memory deleted.'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
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
    );
  }
}
