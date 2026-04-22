/// Configuration for LLM inference.
class ModelConfig {
  const ModelConfig({
    required this.modelPath,
    this.contextLength = 4096,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.systemPrompt = 'You are Luna, a helpful and concise voice assistant.',
  });

  /// Absolute path to the GGUF model file.
  final String modelPath;

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
    int? contextLength,
    double? temperature,
    double? topP,
    String? systemPrompt,
  }) {
    return ModelConfig(
      modelPath: modelPath ?? this.modelPath,
      contextLength: contextLength ?? this.contextLength,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
