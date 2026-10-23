/// Represents a single live fact or reference retrieved from a public API
/// in the `public-apis/public-apis` catalog to ground a persona's response.
class RagCitation {
  final String sourceName;
  final String title;
  final String url;
  final String snippet;
  final String category;

  const RagCitation({
    required this.sourceName,
    required this.title,
    required this.url,
    required this.snippet,
    this.category = 'General',
  });

  Map<String, String> toStringMap() {
    return {
      'sourceName': sourceName,
      'title': title,
      'url': url,
      'snippet': snippet,
      'category': category,
    };
  }

  factory RagCitation.fromMap(Map<String, dynamic> map) {
    return RagCitation(
      sourceName: (map['sourceName'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      snippet: (map['snippet'] ?? '').toString(),
      category: (map['category'] ?? 'General').toString(),
    );
  }
}

/// Aggregated result from [PublicApiRagService] for a persona + user query.
class RagGroundingResult {
  final String personaId;
  final String query;
  final List<RagCitation> citations;
  final DateTime retrievedAt;

  const RagGroundingResult({
    required this.personaId,
    required this.query,
    required this.citations,
    required this.retrievedAt,
  });

  bool get hasContext => citations.isNotEmpty;

  List<Map<String, String>> toSourceMaps() {
    return citations.map((c) => c.toStringMap()).toList();
  }

  /// Builds the structured RAG block injected into the persona's system prompt.
  String toSystemPromptBlock() {
    if (citations.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('=== LIVE GROUNDED RAG DATA (VERIFIED PUBLIC APIs) ===');
    buffer.writeln(
      'The following real-time facts and references were just retrieved from '
      'public APIs to ground your response. Incorporate relevant facts, '
      'version numbers, papers, job listings, or advisories into your answer '
      'and cite the source naturally (e.g., [Source Name](url)):',
    );
    for (int i = 0; i < citations.length; i++) {
      final c = citations[i];
      buffer.writeln(
        '${i + 1}. [${c.sourceName}] ${c.title}\n'
        '   Facts: ${c.snippet}\n'
        '   URL: ${c.url}',
      );
    }
    buffer.writeln('=====================================================');
    return buffer.toString();
  }
}
