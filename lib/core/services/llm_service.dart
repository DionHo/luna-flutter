import 'package:nobodywho/nobodywho.dart';

import '../error/app_exception.dart';
import '../models/model_config.dart';

/// Wraps the [nobodywho] plugin to provide on-device LLM inference.
///
/// Only one model may be resident at a time.  Call [loadModel] before
/// calling [generate]; call [unloadModel] when the model is no longer needed.
class LlmService {
  Chat? _chat;
  ModelConfig? _config;

  bool get isModelLoaded => _chat != null;

  /// Loads the GGUF model at [config.modelPath].
  ///
  /// If a model is already loaded it is unloaded first.
  /// Throws [ModelLoadException] on failure.
  Future<void> loadModel(ModelConfig config) async {
    if (isModelLoaded) {
      await unloadModel();
    }
    try {
      _chat = await Chat.fromPath(
        modelPath: config.modelPath,
        systemPrompt: config.systemPrompt,
        contextSize: config.contextLength,
        sampler: SamplerPresets.temperature(temperature: config.temperature),
      );
      _config = config;
    } catch (e) {
      throw ModelLoadException('Failed to load model at ${config.modelPath}: $e');
    }
  }

  /// Releases native model resources.
  Future<void> unloadModel() async {
    _chat = null;
    _config = null;
  }

  /// Streams generated tokens for [prompt].
  ///
  /// Throws [InferenceException] if the model is not loaded or generation fails.
  Stream<String> generate(String prompt) {
    final chat = _chat;
    if (chat == null) {
      throw const InferenceException('No model loaded. Call loadModel() first.');
    }
    try {
      return chat.ask(prompt);
    } catch (e) {
      throw InferenceException('Inference failed: $e');
    }
  }

  ModelConfig? get currentConfig => _config;
}
