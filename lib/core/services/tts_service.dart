import 'package:kokoro_tts_flutter/kokoro_tts_flutter.dart';

import '../error/app_exception.dart';

/// Wraps [kokoro_tts_flutter] for on-device text-to-speech synthesis.
class TtsService {
  final KokoroTts _tts = KokoroTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Synthesises [text] and plays the result through the device speaker.
  ///
  /// Throws [TtsException] on synthesis or playback failure.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      throw TtsException('TTS synthesis failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Cancels any active synthesis and stops audio playback immediately.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      throw TtsException('TTS stop failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }
}
