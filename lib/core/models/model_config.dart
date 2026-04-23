/// Configuration for LLM inference.
class ModelConfig {
  const ModelConfig({
    required this.modelPath,
    this.projectionModelPath,
    this.contextLength = 4096,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.systemPrompt = 'Answer the question.',
  });

  /// Absolute path to the main GGUF model file.
  final String modelPath;

  /// Absolute path to the multimodal projection model (mmproj).
  /// Required for vision/audio inference with Gemma 4 E2B.
  final String? projectionModelPath;

  /// Maximum token context window.
  final int contextLength;

  /// Sampling temperature (0.0–1.0).
  final double temperature;

  /// Nucleus sampling threshold.
  final double topP;

  /// System prompt prepended to every conversation.
  final String systemPrompt;

  ModelConfig copyWith({
    String? modelPath,
    String? projectionModelPath,
    int? contextLength,
    double? temperature,
    double? topP,
    String? systemPrompt,
  }) {
    return ModelConfig(
      modelPath: modelPath ?? this.modelPath,
      projectionModelPath: projectionModelPath ?? this.projectionModelPath,
      contextLength: contextLength ?? this.contextLength,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
