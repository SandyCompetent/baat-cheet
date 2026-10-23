import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/app_logger.dart';
import '../core/storage_service.dart';
import '../core/text_embedder.dart';
import '../models/relationship_state.dart';
import '../models/user_memory.dart';

/// Production Two-Layer Memory Service for ChatBud.
/// - Layer 1: Working conversation turns.
/// - Layer 2: Long-term episodic memories retrieved via on-device cosine vector similarity
///   and keyword overlap scoring.
/// Includes relationship evolution (trust level and persona mood state).
class MemoryService {
  static final MemoryService instance = MemoryService._internal();

  MemoryService._internal() {
    _loadMemories();
    _loadRelationshipStates();
  }

  /// Upper bound on stored episodic memories. Beyond this, the least valuable
  /// (lowest confidence, least recently recalled) memories are evicted so the
  /// on-device vault stays bounded and fast.
  static const int maxMemories = 200;

  FirebaseFirestore? _customFirestore;
  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _canSyncFirestore => _firestore != null && _currentUser != null;

  @visibleForTesting
  set firestoreForTesting(FirebaseFirestore? fs) {
    _customFirestore = fs;
  }

  final ValueNotifier<List<UserMemory>> memoriesNotifier =
      ValueNotifier<List<UserMemory>>([]);

  final ValueNotifier<Map<String, RelationshipState>>
      relationshipStatesNotifier =
      ValueNotifier<Map<String, RelationshipState>>({});

  void _loadMemories() {
    try {
      final saved = StorageService.getUserMemories();
      memoriesNotifier.value = saved;
    } catch (_) {}
  }

  void _loadRelationshipStates() {
    try {
      final saved = StorageService.getRelationshipStates();
      relationshipStatesNotifier.value = saved;
    } catch (_) {}
  }

  // ── Vector Similarity Math (Pure Dart, Zero Network Latency, 100% Free) ───
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA <= 0.0 || normB <= 0.0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  // ── Memory Addition & Persistence ─────────────────────────────────────────
  Future<UserMemory> addMemory({
    required String fact,
    String? personaId,
    String category = 'preference',
    double confidence = 1.0,
    List<double>? embedding,
  }) async {
    final user = _currentUser;
    final now = DateTime.now();
    final cleanFact = fact.trim();

    // ── De-duplication ────────────────────────────────────────────────────
    // Heuristic fact extraction can emit the same (or near-identical) fact
    // repeatedly. Collapse exact normalized matches and very-high cosine
    // duplicates into the existing memory (refreshing its recency) instead of
    // growing the vault with noise.
    final newEmbedding = embedding ?? TextEmbedder.embed(cleanFact);
    final normalized = _normalizeFact(cleanFact);
    final existingIdx = memoriesNotifier.value.indexWhere((m) {
      if ((m.personaId ?? '') != (personaId ?? '')) return false;
      if (_normalizeFact(m.fact) == normalized) return true;
      final emb = m.embedding;
      return emb != null &&
          emb.length == newEmbedding.length &&
          cosineSimilarity(emb, newEmbedding) > 0.97;
    });
    if (existingIdx != -1) {
      final existing = memoriesNotifier.value[existingIdx];
      final refreshed = existing.copyWith(
        lastRecalledAt: now,
        confidence: max(existing.confidence, confidence),
        embedding: existing.embedding ?? newEmbedding,
      );
      final list = List<UserMemory>.from(memoriesNotifier.value);
      list[existingIdx] = refreshed;
      memoriesNotifier.value = list;
      await StorageService.saveUserMemories(list);
      return refreshed;
    }

    final id = 'mem_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final memory = UserMemory(
      id: id,
      userId: user?.uid ?? 'guest',
      personaId: personaId,
      fact: cleanFact,
      category: category,
      confidence: confidence,
      embedding: newEmbedding,
      createdAt: now,
      lastRecalledAt: now,
    );

    var updated = List<UserMemory>.from(memoriesNotifier.value)..add(memory);
    updated = _enforceCapacity(updated);
    memoriesNotifier.value = updated;
    await StorageService.saveUserMemories(updated);

    if (_canSyncFirestore && user != null) {
      try {
        await _firestore
            ?.collection('users')
            .doc(user.uid)
            .collection('memories')
            .doc(id)
            .set(memory.toMap());
      } catch (e, st) {
        AppLogger.w('Failed to sync memory to Firestore',
            tag: 'MemoryService', error: e, stackTrace: st);
      }
    }

    return memory;
  }

  /// Normalize a fact for duplicate detection: lowercase, collapse whitespace,
  /// strip punctuation.
  static String _normalizeFact(String fact) {
    return fact
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Keep only the [maxMemories] most valuable memories, evicting the lowest
  /// confidence / least recently recalled first.
  static List<UserMemory> _enforceCapacity(List<UserMemory> memories) {
    if (memories.length <= maxMemories) return memories;
    final sorted = List<UserMemory>.from(memories)
      ..sort((a, b) {
        final byConfidence = b.confidence.compareTo(a.confidence);
        if (byConfidence != 0) return byConfidence;
        return b.lastRecalledAt.compareTo(a.lastRecalledAt);
      });
    return sorted.take(maxMemories).toList();
  }

  Future<void> deleteMemory(String id) async {
    final updated = memoriesNotifier.value.where((m) => m.id != id).toList();
    memoriesNotifier.value = updated;
    await StorageService.saveUserMemories(updated);

    final user = _currentUser;
    if (_canSyncFirestore && user != null) {
      try {
        await _firestore
            ?.collection('users')
            .doc(user.uid)
            .collection('memories')
            .doc(id)
            .delete();
      } catch (e, st) {
        AppLogger.w('Failed to delete memory from Firestore',
            tag: 'MemoryService', error: e, stackTrace: st);
      }
    }
  }

  // ── Retrieval: Semantic Vector Ranking & Keyword Fallback ──────────────────
  List<UserMemory> retrieveRelevantMemories({
    required String query,
    String? personaId,
    List<double>? queryEmbedding,
    int limit = 4,
  }) {
    final all = memoriesNotifier.value;
    if (all.isEmpty) return [];

    // Filter to general or persona-specific memories
    final candidates = all.where((m) {
      return m.personaId == null || m.personaId == personaId;
    }).toList();

    if (candidates.isEmpty) return [];

    final scored = <MapEntry<UserMemory, double>>[];

    // Embed the query on-device (free, <1ms) when an embedding was not supplied
    // so the vector-similarity path is always active, not just a fallback.
    final effectiveQueryEmbedding = queryEmbedding ?? TextEmbedder.embed(query);

    final queryTokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toSet();

    for (final memory in candidates) {
      double score = 0.0;

      // 1. Vector similarity if embeddings are present
      final memEmbedding = memory.embedding;
      if (memEmbedding != null &&
          effectiveQueryEmbedding.length == memEmbedding.length) {
        score += cosineSimilarity(effectiveQueryEmbedding, memEmbedding) * 3.0;
      }

      // 2. Token overlap score
      final factTokens = memory.fact
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((t) => t.length > 2)
          .toSet();

      final intersection = queryTokens.intersection(factTokens).length;
      if (factTokens.isNotEmpty) {
        score += (intersection / factTokens.length);
      }

      // Slight boost for high confidence and recent recall
      score += (memory.confidence * 0.1);

      if (score > 0.05) {
        scored.add(MapEntry(memory, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  // ── Relationship State Tracking ───────────────────────────────────────────
  RelationshipState getRelationshipState(String personaId) {
    final states = relationshipStatesNotifier.value;
    if (states.containsKey(personaId)) {
      return states[personaId]!;
    }
    return RelationshipState(
      personaId: personaId,
      trustLevel: 1,
      mood: 'Supportive',
      interactionCount: 0,
      lastInteraction: DateTime.now(),
    );
  }

  Future<void> recordInteraction(
    String personaId, {
    String? moodOverride,
    String? note,
  }) async {
    final current = getRelationshipState(personaId);
    final newCount = current.interactionCount + 1;

    // Trust evolves gently based on interaction depth
    int newTrust = current.trustLevel;
    if (newCount == 3) newTrust = 2;
    if (newCount == 10) newTrust = 4;
    if (newCount == 25) newTrust = 6;
    if (newCount == 50) newTrust = 8;
    if (newCount >= 100) newTrust = 10;

    final updated = current.copyWith(
      interactionCount: newCount,
      trustLevel: newTrust,
      mood: moodOverride ?? current.mood,
      lastInteraction: DateTime.now(),
      notes: note ?? current.notes,
    );

    final map = Map<String, RelationshipState>.from(
      relationshipStatesNotifier.value,
    );
    map[personaId] = updated;
    relationshipStatesNotifier.value = map;
    await StorageService.saveRelationshipStates(map);
  }

  // ── Dynamic System Prompt Injection ───────────────────────────────────────
  String buildSystemPrompt({
    required String basePrompt,
    required String personaId,
    required String currentQuery,
    List<double>? queryEmbedding,
    String? ragContextBlock,
  }) {
    final memories = retrieveRelevantMemories(
      query: currentQuery,
      personaId: personaId,
      queryEmbedding: queryEmbedding,
    );
    // Mark the injected memories as freshly recalled (recency signal feeds
    // capacity eviction). Fire-and-forget so prompt building stays synchronous.
    if (memories.isNotEmpty) {
      unawaited(_touchRecalled(memories));
    }
    final relationship = getRelationshipState(personaId);

    final buffer = StringBuffer(basePrompt);
    buffer.writeln('\n');

    buffer.writeln('=== CONTEXT & LONG-TERM MEMORY ===');
    buffer.writeln(
      'Relationship with user: Trust Level ${relationship.trustLevel}/10, '
      'Current Persona Mood: ${relationship.mood}, Total Interactions: ${relationship.interactionCount}.',
    );

    if (memories.isNotEmpty) {
      buffer.writeln('Recalled facts about the user:');
      for (final mem in memories) {
        buffer.writeln('- ${mem.fact}');
      }
    }
    buffer.writeln('===================================');

    if (ragContextBlock != null && ragContextBlock.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(ragContextBlock.trim());
    }

    return buffer.toString();
  }

  /// Refresh `lastRecalledAt` for the given memories and persist locally.
  Future<void> _touchRecalled(List<UserMemory> recalled) async {
    final ids = recalled.map((m) => m.id).toSet();
    if (ids.isEmpty) return;
    final now = DateTime.now();
    final list = memoriesNotifier.value
        .map((m) => ids.contains(m.id) ? m.copyWith(lastRecalledAt: now) : m)
        .toList();
    memoriesNotifier.value = list;
    await StorageService.saveUserMemories(list);
  }
}
