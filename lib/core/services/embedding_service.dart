import 'package:nobodywho/nobodywho.dart' as nobodywho;

import '../error/app_exception.dart';

/// Wraps the [nobodywho.Encoder] for computing semantic embedding vectors.
///
/// Used by [RagService] for the first stage of the RAG pipeline (fast
/// cosine-similarity filtering before the slower cross-encoder reranker).
///
/// Typical usage:
/// ```dart
/// final svc = EmbeddingService();
/// await svc.loadModel('assets/models/embedding-model.gguf');
/// final vec = await svc.encode('What is the capital of France?');
/// ```
class EmbeddingService {
  nobodywho.Encoder? _encoder;

  bool get isLoaded => _encoder != null;

  /// Loads an embedding GGUF model from [modelPath].
  ///
  /// Throws [ModelLoadException] on failure.
  Future<void> loadModel(String modelPath) async {
    try {
      _encoder = await nobodywho.Encoder.fromPath(modelPath: modelPath);
    } catch (e) {
      throw ModelLoadException(
        'Failed to load embedding model at $modelPath: $e',
      );
    }
  }

  /// Encodes [text] into a dense float vector.
  ///
  /// Throws [InferenceException] if the model is not loaded.
  Future<List<double>> encode(String text) async {
    final encoder = _encoder;
    if (encoder == null) {
      throw const InferenceException(
        'Embedding model not loaded. Call loadModel() first.',
      );
    }
    try {
      final embedding = await encoder.encode(text: text);
      return embedding.toList();
    } catch (e) {
      throw InferenceException('Embedding failed: $e');
    }
  }

  /// Releases native model resources.
  void unloadModel() {
    final enc = _encoder;
    if (enc != null && !enc.isDisposed) enc.dispose();
    _encoder = null;
  }

  void dispose() => unloadModel();
}
