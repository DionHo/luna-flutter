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

  /// Cancels any in-progress token generation.
  ///
  /// Safe to call even when no generation is running.
  void stopGeneration() {
    _chat?.stopGeneration();
  }

  ModelConfig? get currentConfig => _config;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Strips `<think>…</think>` reasoning blocks that some models (e.g. QwQ,
/// DeepSeek-R1, Gemma 4) emit before their visible response.
///
/// Mirrors the `skipThinkingTags` helper from the nobodywho flutter-starter-example.
Stream<String> skipThinkingTags(Stream<String> source) async* {
  bool inThink = false;
  final sb = StringBuffer();

  await for (final chunk in source) {
    sb.write(chunk);

    while (sb.isNotEmpty) {
      final buffer = sb.toString();
      if (inThink) {
        final endIdx = buffer.indexOf('</think>');
        if (endIdx == -1) {
          sb.clear();
          break;
        }
        sb
          ..clear()
          ..write(buffer.substring(endIdx + '</think>'.length));
        inThink = false;
      } else {
        final startIdx = buffer.indexOf('<think>');
        if (startIdx == -1) {
          yield buffer;
          sb.clear();
          break;
        }
        if (startIdx > 0) yield buffer.substring(0, startIdx);
        sb
          ..clear()
          ..write(buffer.substring(startIdx + '<think>'.length));
        inThink = true;
      }
    }
  }

  if (!inThink && sb.isNotEmpty) yield sb.toString();
}
