import 'package:nobodywho/nobodywho.dart' as nobodywho;

import '../error/app_exception.dart';

/// Two-stage RAG (Retrieval-Augmented Generation) pipeline.
///
/// Stage 1 — Embedding-based filtering ([nobodywho.Encoder] + cosine similarity):
///   Quickly narrows the full document corpus down to [candidateCount] candidates.
///
/// Stage 2 — Cross-encoder reranking ([nobodywho.CrossEncoder]):
///   Re-scores the candidates with a more precise model and returns the top [topK].
///
/// Mirrors the RAG pattern from the nobodywho flutter-starter-example.
///
/// Typical usage:
/// ```dart
/// final svc = RagService();
/// await svc.loadModels(
///   embeddingModelPath: 'assets/models/embedding-model.gguf',
///   rerankerModelPath:  'assets/models/reranker-model.gguf',
/// );
/// final results = await svc.search(
///   query: 'What Python libraries are best for data analysis?',
///   documents: myKnowledgeBase,
/// );
/// // Pass results as context to LlmService.generate().
/// ```
class RagService {
  nobodywho.Encoder? _encoder;
  nobodywho.CrossEncoder? _crossEncoder;

  bool get isLoaded => _encoder != null && _crossEncoder != null;

  /// Loads both GGUF models required for the RAG pipeline.
  ///
  /// Throws [ModelLoadException] on failure.
  Future<void> loadModels({
    required String embeddingModelPath,
    required String rerankerModelPath,
  }) async {
    try {
      _encoder = await nobodywho.Encoder.fromPath(
        modelPath: embeddingModelPath,
      );
      _crossEncoder = await nobodywho.CrossEncoder.fromPath(
        modelPath: rerankerModelPath,
      );
    } catch (e) {
      throw ModelLoadException('Failed to load RAG models: $e');
    }
  }

  /// Searches [documents] for the most relevant entries given [query].
  ///
  /// Returns up to [topK] documents sorted by relevance (most relevant first).
  /// [candidateCount] controls how many embedding-stage candidates are passed
  /// to the (slower) cross-encoder reranker — higher values improve recall
  /// at the cost of latency.
  ///
  /// Throws [InferenceException] if [loadModels] has not been called.
  Future<List<String>> search({
    required String query,
    required List<String> documents,
    int topK = 3,
    int candidateCount = 20,
  }) async {
    final encoder = _encoder;
    final crossEncoder = _crossEncoder;
    if (encoder == null || crossEncoder == null) {
      throw const InferenceException(
        'RAG models not loaded. Call loadModels() first.',
      );
    }

    // Stage 1: cosine-similarity filtering on embedding vectors.
    final queryEmbedding = await encoder.encode(text: query);
    final similarities = <(String, double)>[];
    for (final doc in documents) {
      final docEmbedding = await encoder.encode(text: doc);
      final score = nobodywho.cosineSimilarity(
        a: queryEmbedding.toList(),
        b: docEmbedding.toList(),
      );
      similarities.add((doc, score));
    }
    similarities.sort((a, b) => b.$2.compareTo(a.$2));
    final candidates =
        similarities.take(candidateCount).map((e) => e.$1).toList();

    // Stage 2: cross-encoder reranking for precise relevance scoring.
    final ranked = await crossEncoder.rankAndSort(
      query: query,
      documents: candidates,
    );
    return ranked.take(topK).map((e) => e.$1).toList();
  }

  /// Releases all native model resources.
  void unloadModels() {
    final enc = _encoder;
    if (enc != null && !enc.isDisposed) enc.dispose();
    final ce = _crossEncoder;
    if (ce != null && !ce.isDisposed) ce.dispose();
    _encoder = null;
    _crossEncoder = null;
  }

  void dispose() => unloadModels();
}
