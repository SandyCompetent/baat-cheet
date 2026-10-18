import 'package:chatbud/src/core/text_embedder.dart';
import 'package:chatbud/src/services/memory_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextEmbedder', () {
    test('produces a fixed-dimension vector', () {
      final v = TextEmbedder.embed('Flutter riverpod architecture');
      expect(v.length, TextEmbedder.dimensions);
    });

    test('is deterministic for the same input', () {
      final a = TextEmbedder.embed('scalable distributed systems design');
      final b = TextEmbedder.embed('scalable distributed systems design');
      expect(a, equals(b));
    });

    test('empty / stopword-only input yields a zero vector', () {
      final v = TextEmbedder.embed('the and for');
      expect(v.every((x) => x == 0.0), isTrue);
    });

    test('vectors are L2-normalized (unit length) for real content', () {
      final v = TextEmbedder.embed('cybersecurity threat modeling owasp');
      final sumSq = v.fold<double>(0.0, (acc, x) => acc + x * x);
      expect(sumSq, closeTo(1.0, 0.0001));
    });

    test('related texts score higher than unrelated texts via cosine', () {
      final query = TextEmbedder.embed(
        'what flutter state management architecture should I use',
      );
      final related = TextEmbedder.embed(
        'I prefer riverpod architecture over provider in flutter',
      );
      final unrelated = TextEmbedder.embed(
        'the best recipe for a chocolate birthday cake',
      );

      final relatedScore = MemoryService.cosineSimilarity(query, related);
      final unrelatedScore = MemoryService.cosineSimilarity(query, unrelated);

      expect(relatedScore, greaterThan(unrelatedScore));
      expect(relatedScore, greaterThan(0.0));
    });
  });
}
