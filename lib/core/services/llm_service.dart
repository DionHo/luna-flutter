import 'package:nobodywho/nobodywho.dart' as nobodywho;

import '../error/app_exception.dart';
import '../models/model_config.dart';

/// Wraps the [nobodywho] plugin to provide on-device LLM inference.
///
/// Only one model may be resident at a time.  Call [loadModel] before
/// calling [generate] or [generateFromAudio]; call [unloadModel] when
/// the model is no longer needed.
class LlmService {
  nobodywho.Chat? _chat;
  nobodywho.Model? _model;
  ModelConfig? _config;

  bool get isModelLoaded => _chat != null;

  /// Loads the GGUF model at [config.modelPath], optionally with a multimodal
  /// projection model at [config.projectionModelPath].
  ///
  /// If a model is already loaded it is unloaded first.
  /// Throws [ModelLoadException] on failure.
  Future<void> loadModel(ModelConfig config) async {
    if (isModelLoaded) {
      await unloadModel();
    }
    try {
      _model = await nobodywho.Model.load(
        modelPath: config.modelPath,
        projectionModelPath: config.projectionModelPath,
      );
      _chat = nobodywho.Chat(
        model: _model!,
        systemPrompt: config.systemPrompt,
        contextSize: config.contextLength,
      );
      _config = config;
    } catch (e) {
      throw ModelLoadException('Failed to load model at ${config.modelPath}: $e');
    }
  }

  /// Releases native model resources.
  Future<void> unloadModel() async {
    _chat = null;
    _model = null;
    _config = null;
  }

  /// Streams generated tokens for a text [prompt].
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

  /// Streams generated tokens for an audio file at [audioPath].
  ///
  /// Sends the audio to the model as an [AudioPart] with the system prompt
  /// "Answer the question." so the model transcribes and responds to the
  /// spoken content.
  ///
  /// Throws [InferenceException] if the model is not loaded or inference fails.
  Stream<String> generateFromAudio(String audioPath) {
    final chat = _chat;
    if (chat == null) {
      throw const InferenceException('No model loaded. Call loadModel() first.');
    }
    try {
      return chat.askWithPrompt(
        nobodywho.Prompt([
          const nobodywho.TextPart('Answer the question.'),
          nobodywho.AudioPart(audioPath),
        ]),
      );
    } catch (e) {
      throw InferenceException('Audio inference failed: $e');
    }
  }

  ModelConfig? get currentConfig => _config;
}
