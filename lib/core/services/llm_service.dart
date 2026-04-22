import 'package:nobodywho/nobodywho.dart';

import '../error/app_exception.dart';
import '../models/model_config.dart';

/// Wraps the [nobodywho] plugin to provide on-device LLM inference.
///
/// Only one model may be resident at a time.  Call [loadModel] before
/// calling [generate]; call [unloadModel] when the model is no longer needed.
class LlmService {
  NobodywhoModel? _model;
  NobodywhoSession? _session;
  ModelConfig? _config;

  bool get isModelLoaded => _model != null;

  /// Loads the GGUF model at [config.modelPath].
  ///
  /// If a model is already loaded it is unloaded first.
  /// Throws [ModelLoadException] on failure.
  Future<void> loadModel(ModelConfig config) async {
    if (isModelLoaded) {
      await unloadModel();
    }
    try {
      final model = NobodywhoModel(modelPath: config.modelPath);
      await model.load();
      _model = model;
      _config = config;
      _session = model.createSession(
        systemPrompt: config.systemPrompt,
        temperature: config.temperature,
        topP: config.topP,
        contextLength: config.contextLength,
      );
    } catch (e) {
      throw ModelLoadException('Failed to load model at ${config.modelPath}: $e');
    }
  }

  /// Releases native model resources.
  Future<void> unloadModel() async {
    _session?.dispose();
    await _model?.dispose();
    _session = null;
    _model = null;
    _config = null;
  }

  /// Streams generated tokens for [prompt].
  ///
  /// Throws [InferenceException] if the model is not loaded or generation fails.
  Stream<String> generate(String prompt) {
    final session = _session;
    if (session == null) {
      throw const InferenceException('No model loaded. Call loadModel() first.');
    }
    try {
      return session.getCompletion(prompt: prompt);
    } catch (e) {
      throw InferenceException('Inference failed: $e');
    }
  }

  ModelConfig? get currentConfig => _config;
}
