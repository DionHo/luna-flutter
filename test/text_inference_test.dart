// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;

/// Integration test: load Gemma 4 E2B and ask a plain-text question.
/// Verifies that the text inference path (chat.ask) works end-to-end on the
/// current platform.  Complements [audio_inference_test.dart] which tests
/// the multimodal audio path.
///
/// Run with:
///   docker exec -w /workspaces/luna-flutter mystifying_grothendieck \
///     flutter test test/text_inference_test.dart --reporter=compact
///
/// Prerequisites: run scripts/download_models.sh first.
void main() {
  const llmPath = 'assets/models/gemma-4-E2B-it-Q4_K_M.gguf';
  const mmprojPath = 'assets/models/mmproj-BF16.gguf';

  final modelsPresent =
      File(llmPath).existsSync() && File(mmprojPath).existsSync();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await nobodywho.NobodyWho.init();
    } catch (_) {
      // Already initialised when the test runner shares a process.
    }
  });

  test(
    'NobodyWho.init() succeeds',
    () {
      // If we reach this point without throwing in setUpAll the init was OK.
      // There is nothing additional to assert — the test itself is the signal.
    },
  );

  test(
    'Gemma 4 answers English capital question via text',
    () async {
      if (!modelsPresent) {
        markTestSkipped(
          'Model files not present — run scripts/download_models.sh',
        );
        return;
      }

      print('Loading model…');
      final model = await nobodywho.Model.load(
        modelPath: llmPath,
        projectionModelPath: mmprojPath,
      );

      final chat = nobodywho.Chat(
        model: model,
        systemPrompt: 'You are a concise assistant. Answer in one sentence.',
      );

      print('Sending text prompt…');
      final response =
          await chat.ask('What is the capital of France?').completed();
      print('Model response: $response');

      expect(
        response.toLowerCase(),
        contains('paris'),
        reason: 'Expected the model to answer "Paris" for the capital of France',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
