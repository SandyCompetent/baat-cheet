import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme_data.dart';
import '../models/persona.dart';
import '../models/rag_citation.dart';
import '../services/public_api_rag_service.dart';

/// Interactive bottom sheet allowing users to inspect and test the live
/// Grounded RAG Engine (`public-apis/public-apis`) powering any ChatBud persona.
class RagLiveSheet extends StatefulWidget {
  final Persona persona;
  final VoidCallback? onStartChat;

  const RagLiveSheet({
    super.key,
    required this.persona,
    this.onStartChat,
  });

  static Future<void> show(
    BuildContext context, {
    required Persona persona,
    VoidCallback? onStartChat,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RagLiveSheet(
        persona: persona,
        onStartChat: onStartChat,
      ),
    );
  }

  @override
  State<RagLiveSheet> createState() => _RagLiveSheetState();
}

class _RagLiveSheetState extends State<RagLiveSheet> {
  late final TextEditingController _queryCtrl;
  late final TextEditingController _apiKeyCtrl;
  bool _isLoading = false;
  bool _showApiKeyInput = false;
  List<RagCitation> _citations = const [];

  @override
  void initState() {
    super.initState();
    final defaultQuery = widget.persona.starterPrompts.isNotEmpty
        ? widget.persona.starterPrompts.first
            .replaceAll(RegExp(r'^[^\w]+'), '')
            .trim()
        : widget.persona.tagline;
    _queryCtrl = TextEditingController(text: defaultQuery);
    _apiKeyCtrl =
        TextEditingController(text: PublicApiRagService.instance.apiKey);
    _runLiveRetrieval();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _runLiveRetrieval() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() => _isLoading = true);
    final res = await PublicApiRagService.instance.retrieveGroundingContext(
      personaId: widget.persona.id,
      query: q,
      personaCategory: widget.persona.category,
    );
    if (!mounted) return;
    setState(() {
      _citations = res.citations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.accentSubtle,
                child: Icon(
                  Icons.hub_rounded,
                  color: context.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.persona.name} · Grounded RAG Engine',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      PublicApiRagService.instance.hasCustomApiKey
                          ? 'Live RAG + APILayer Key active'
                          : 'Live zero-auth retrieval via public-apis/public-apis',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Configure APILayer / Public API Key',
                icon: Icon(
                  Icons.vpn_key_outlined,
                  size: 19,
                  color: PublicApiRagService.instance.hasCustomApiKey
                      ? context.accent
                      : context.textSecondary,
                ),
                onPressed: () {
                  setState(() => _showApiKeyInput = !_showApiKeyInput);
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (_showApiKeyInput) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              style: TextStyle(color: context.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'APILayer / Public API Key (Optional)',
                hintText: 'Paste APILayer key or configure in Profile tab...',
                prefixIcon: Icon(
                  Icons.vpn_key_outlined,
                  size: 17,
                  color: context.accent,
                ),
                suffixIcon: _apiKeyCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _apiKeyCtrl.clear();
                          PublicApiRagService.instance.setApiKey('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                PublicApiRagService.instance.setApiKey(val);
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.persona.ragApis.map((api) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: context.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      api,
                      style: TextStyle(
                        color: context.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  onSubmitted: (_) => _runLiveRetrieval(),
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText:
                        'Test a live RAG query for ${widget.persona.name}...',
                    hintStyle:
                        TextStyle(color: context.textMuted, fontSize: 12),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: context.accent,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _isLoading ? null : _runLiveRetrieval,
                icon: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Fetch'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _citations.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.bgElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ready to ground ${widget.persona.name} responses with live data from ${widget.persona.ragApis.join(", ")}. Start a chat or test another query above.',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _citations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = _citations[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.bgElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.accentSubtle,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        c.sourceName,
                                        style: TextStyle(
                                          color: context.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (c.url.isNotEmpty)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.open_in_new_rounded,
                                          size: 15,
                                          color: context.accent,
                                        ),
                                        onPressed: () async {
                                          final uri = Uri.tryParse(c.url);
                                          if (uri != null) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.snippet,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (widget.onStartChat != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onStartChat!();
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text('Chat with ${widget.persona.name} (Grounded RAG)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
