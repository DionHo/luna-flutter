// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;

/// Integration test: load Gemma 4 E2B with its BF16 mmproj and ask a spoken
/// German question ("Wie heißt die Hauptstadt von Deutschland?") via an MP3
/// audio file.  The model should respond with an answer containing "Berlin".
///
/// Run with:
///   docker exec -w /workspaces/luna-flutter mystifying_grothendieck \
///     flutter test test/audio_inference_test.dart --reporter=compact
///
/// Prerequisites: run scripts/download_models.sh first.
void main() {
  const llmPath = 'assets/models/gemma-4-E2B-it-Q4_K_M.gguf';
  const mmprojPath = 'assets/models/mmproj-BF16.gguf';
  const audioPath = 'test/input/test-question-berlin.mp3';

  final modelsPresent =
      File(llmPath).existsSync() && File(mmprojPath).existsSync();
  final audioPresent = File(audioPath).existsSync();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await nobodywho.NobodyWho.init();
    } on StateError {
      // NobodyWho.init() was already called in this test process — ignore.
      // Any other exception (e.g. library not found) is a real failure and
      // must propagate so that the test suite fails loudly.
    }
  });

  test(
    'Gemma 4 answers German capital question via audio',
    () async {
      if (!modelsPresent) {
        printOnFailure(
          'SKIP: model files not found at $llmPath / $mmprojPath\n'
          'Run scripts/download_models.sh before executing this test.',
        );
        markTestSkipped(
          'Model files not present — run scripts/download_models.sh',
        );
      }

      expect(audioPresent, isTrue,
          reason: 'Test audio file missing: $audioPath');

      // ── Load model ──────────────────────────────────────────────────────
      print('Loading model…');
      final model = await nobodywho.Model.load(
        modelPath: llmPath,
        projectionModelPath: mmprojPath,
      );

      final chat = nobodywho.Chat(
        model: model,
        systemPrompt: 'Answer the question.',
      );

      // ── Run audio inference ─────────────────────────────────────────────
      // The audio file contains: "Wie heißt die Hauptstadt von Deutschland?"
      // (German: "What is the capital of Germany?")
      print('Sending audio to model…');
      final response = await chat
          .askWithPrompt(
            const nobodywho.Prompt([
              nobodywho.AudioPart(audioPath),
            ]),
          )
          .completed();

      print('Model response: $response');

      // ── Assert ──────────────────────────────────────────────────────────
      expect(
        response.toLowerCase(),
        contains('berlin'),
        reason: 'Expected the model to mention "Berlin" as the capital of Germany',
      );
    },
    timeout: const Timeout(Duration(minutes: 15)),
    skip: !modelsPresent
        ? 'Model files not present — run scripts/download_models.sh'
        : null,
  );
}
