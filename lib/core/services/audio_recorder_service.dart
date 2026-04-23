import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Wraps the [record] plugin to provide microphone capture for push-to-talk.
///
/// Usage:
///   1. Call [startRecording] when the PTT button is pressed.
///   2. Call [stopRecording] when the button is released — returns the path to
///      a WAV file suitable for passing to [LlmService.generateFromAudio].
///
/// Dispose via [dispose] when the owning widget / provider is torn down.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Returns true if the app has microphone permission.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording to a temporary WAV file (16 kHz, mono, 16-bit PCM).
  Future<void> startRecording() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(tempDir.path, 'luna_ptt_recording.wav');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: filePath,
    );
  }

  /// Stops recording and returns the path to the recorded WAV file, or
  /// [null] if nothing was recorded.
  Future<String?> stopRecording() => _recorder.stop();

  /// Releases native recorder resources.
  Future<void> dispose() => _recorder.dispose();
}
