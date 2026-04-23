import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:kokoro_tts_flutter/kokoro_tts_flutter.dart';

import '../error/app_exception.dart';

/// Wraps [kokoro_tts_flutter] for on-device text-to-speech synthesis.
///
/// Call [initialize] with the on-device model and voices file paths before
/// calling [speak].  Audio is played through the device speaker via
/// [audioplayers].
class TtsService {
  Kokoro? _kokoro;
  final AudioPlayer _player = AudioPlayer();
  String _defaultVoice = 'af_heart';
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Initialises the Kokoro TTS engine.
  ///
  /// [modelPath] and [voicesPath] must point to the on-device ONNX model and
  /// voices JSON file respectively.  [defaultVoice] selects the voice used by
  /// [speak]; it can be any voice ID present in the voices file.
  Future<void> initialize({
    required String modelPath,
    required String voicesPath,
    String defaultVoice = 'af_heart',
  }) async {
    final config = KokoroConfig(modelPath: modelPath, voicesPath: voicesPath);
    _kokoro = Kokoro(config);
    await _kokoro!.initialize();
    _defaultVoice = defaultVoice;
  }

  /// Synthesises [text] and plays the result through the device speaker.
  ///
  /// Throws [TtsException] on synthesis or playback failure.
  Future<void> speak(String text) async {
    final kokoro = _kokoro;
    if (kokoro == null) {
      throw const TtsException('TtsService not initialised. Call initialize() first.');
    }
    if (text.trim().isEmpty) return;
    try {
      _isSpeaking = true;
      final result = await kokoro.createTTS(text: text, voice: _defaultVoice);
      await _player.play(BytesSource(_toWav(result)));
    } catch (e) {
      throw TtsException('TTS synthesis failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Cancels any active synthesis and stops audio playback immediately.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      throw TtsException('TTS stop failed: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  /// Releases all resources held by the TTS engine and audio player.
  Future<void> dispose() async {
    await _player.dispose();
    await _kokoro?.dispose();
    _kokoro = null;
  }

  /// Wraps raw Int16 PCM samples from [result] in a minimal RIFF/WAV header
  /// so that [audioplayers] can decode and play the audio directly from memory.
  static Uint8List _toWav(TtsResult result) {
    const channels = 1;
    const bitsPerSample = 16;
    final sampleRate = result.sampleRate;
    final pcm = result.toInt16PCM();
    final dataSize = pcm.lengthInBytes;
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    const blockAlign = channels * (bitsPerSample ~/ 8);

    final header = ByteData(44);
    // RIFF chunk
    _writeAscii(header, 0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(header, 8, 'WAVE');
    // fmt sub-chunk
    _writeAscii(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM = 1
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    _writeAscii(header, 36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataSize, pcm.buffer.asUint8List());
    return out;
  }

  static void _writeAscii(ByteData buf, int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      buf.setUint8(offset + i, text.codeUnitAt(i));
    }
  }
}
