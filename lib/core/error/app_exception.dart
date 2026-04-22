/// Base class for all domain errors in Luna Flutter.
///
/// Providers catch these at the service call site and emit
/// [AsyncValue.error] so the UI can render an error state.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The GGUF model could not be loaded (file missing, OOM, etc.).
final class ModelLoadException extends AppException {
  const ModelLoadException(super.message);
}

/// llama.cpp returned an error during token generation.
final class InferenceException extends AppException {
  const InferenceException(super.message);
}

/// kokoro_tts_flutter failed to synthesise or play audio.
final class TtsException extends AppException {
  const TtsException(super.message);
}

/// A SQLite operation failed.
final class DatabaseException extends AppException {
  const DatabaseException(super.message);
}
