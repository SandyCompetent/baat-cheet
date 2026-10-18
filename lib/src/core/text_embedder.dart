import 'dart:math';

/// On-device, zero-cost text embedder used by the Two-Layer Memory Engine.
///
/// This is a deterministic **feature-hashing** (a.k.a. "hashing trick") term
/// embedder implemented in pure Dart. It projects tokenized text into a
/// fixed-dimensional L2-normalized vector so that [MemoryService] can rank
/// memories with real cosine similarity — fully on-device, with no network
/// calls, no API keys, and sub-millisecond latency.
///
/// Design notes / honest scope:
/// - This is a lexical embedding (unigrams + bigrams via the hashing trick),
///   NOT a large neural semantic embedding. It captures term overlap and
///   co-occurrence robustly and cheaply. Two texts that share words/phrases
///   land close together; unrelated texts stay near-orthogonal.
/// - It is intentionally stable: the same input always yields the same vector,
///   so embeddings can be persisted in [StorageService]/Firestore and compared
///   across sessions and devices without re-computation drift.
/// - If a true semantic embedding provider is wired in later, memories simply
///   carry a different embedding vector; the cosine ranking code is unchanged.
class TextEmbedder {
  const TextEmbedder._();

  /// Dimensionality of the embedding space. 256 keeps hash collisions low for
  /// short conversational facts while staying tiny in memory/storage.
  static const int dimensions = 256;

  static final RegExp _nonWord = RegExp(r'[^\w\s]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Lightweight English stopword list — dropped so high-frequency function
  /// words do not dominate the vector.
  static const Set<String> _stopwords = {
    'the',
    'and',
    'for',
    'are',
    'but',
    'not',
    'you',
    'all',
    'any',
    'can',
    'her',
    'was',
    'one',
    'our',
    'out',
    'his',
    'has',
    'had',
    'how',
    'who',
    'she',
    'him',
    'its',
    'did',
    'yes',
    'this',
    'that',
    'with',
    'from',
    'your',
    'have',
    'what',
    'when',
    'will',
    'would',
    'should',
    'could',
    'there',
    'their',
    'about',
    'into',
    'then',
    'than',
    'them',
    'they',
  };

  /// Tokenize text into normalized, meaningful tokens (lowercased, punctuation
  /// stripped, short tokens and stopwords removed).
  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(_nonWord, ' ')
        .split(_whitespace)
        .where((t) => t.length > 2 && !_stopwords.contains(t))
        .toList();
  }

  /// Produce an L2-normalized embedding vector for [text].
  ///
  /// Uses unigrams and adjacent bigrams, each hashed into the vector with a
  /// sign hash (to reduce systematic collision bias). Returns a zero vector
  /// for empty/meaningless input.
  static List<double> embed(String text) {
    final vector = List<double>.filled(dimensions, 0.0);
    final tokens = tokenize(text);
    if (tokens.isEmpty) return vector;

    void add(String feature, double weight) {
      final h = feature.hashCode;
      final index = (h & 0x7fffffff) % dimensions;
      final sign = ((h >> 31) & 1) == 0 ? 1.0 : -1.0;
      vector[index] += sign * weight;
    }

    for (var i = 0; i < tokens.length; i++) {
      add(tokens[i], 1.0);
      if (i + 1 < tokens.length) {
        // Bigrams carry a little less weight than unigrams.
        add('${tokens[i]}_${tokens[i + 1]}', 0.5);
      }
    }

    return _l2Normalize(vector);
  }

  static List<double> _l2Normalize(List<double> v) {
    double sumSq = 0.0;
    for (final x in v) {
      sumSq += x * x;
    }
    if (sumSq <= 0.0) return v;
    final norm = sqrt(sumSq);
    for (var i = 0; i < v.length; i++) {
      v[i] = v[i] / norm;
    }
    return v;
  }
}
