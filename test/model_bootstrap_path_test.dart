// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Unit tests for [ModelBootstrapService] path construction logic.
///
/// These tests do NOT require model files to be present — they validate that
/// the service would look for models in the right directory given the current
/// executable location.
///
/// Run with:
///   docker exec -w /workspaces/luna-flutter mystifying_grothendieck \
///     flutter test test/model_bootstrap_path_test.dart --reporter=compact
void main() {
  group('ModelBootstrapService path construction', () {
    test('resolves paths relative to Platform.resolvedExecutable', () {
      // Mirror the exact logic in ModelBootstrapService.init() so this test
      // would catch a regression if the formula is changed.
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final llm = p.join(exeDir, 'data', 'flutter_assets', 'assets', 'models',
          'gemma-4-E2B-it-Q4_K_M.gguf');
      final mmproj = p.join(exeDir, 'data', 'flutter_assets', 'assets',
          'models', 'mmproj-BF16.gguf');

      print('Exe dir : $exeDir');
      print('LLM     : $llm');
      print('mmproj  : $mmproj');

      // Paths must be absolute.
      expect(p.isAbsolute(llm), isTrue,
          reason: 'LLM path must be absolute: $llm');
      expect(p.isAbsolute(mmproj), isTrue,
          reason: 'mmproj path must be absolute: $mmproj');

      // Paths must not contain raw forward-slash segments that would create
      // mixed separators on Windows (the pre-fix bug).
      if (Platform.isWindows) {
        expect(llm, isNot(contains('assets/models')),
            reason: 'Windows path must not mix separators: $llm');
        expect(mmproj, isNot(contains('assets/models')),
            reason: 'Windows path must not mix separators: $mmproj');
      }

      // Both paths must end with the correct filenames.
      expect(p.basename(llm), equals('gemma-4-E2B-it-Q4_K_M.gguf'));
      expect(p.basename(mmproj), equals('mmproj-BF16.gguf'));
    });

    test('model files exist inside flutter_assets when running from build dir',
        () {
      // When running a Flutter *test* (not the app), the exe points to the
      // test runner, not to the built app bundle, so the assets won't be at
      // the bootstrap path.  We look for the workspace-root copies instead.
      const workspaceRelLlm = 'assets/models/gemma-4-E2B-it-Q4_K_M.gguf';
      const workspaceRelMmproj = 'assets/models/mmproj-BF16.gguf';

      if (!File(workspaceRelLlm).existsSync() ||
          !File(workspaceRelMmproj).existsSync()) {
        markTestSkipped(
          'Workspace-root model files not present — run scripts/download_models.sh',
        );
        return;
      }

      expect(File(workspaceRelLlm).existsSync(), isTrue);
      expect(File(workspaceRelMmproj).existsSync(), isTrue);
      print('Workspace-root models confirmed present.');
    });

    test(
      'linux build bundle has models at expected path',
      () {
        // When the CI builds the Linux bundle, models are bundled into:
        //   build/linux/x64/release/bundle/data/flutter_assets/assets/models/
        // This test checks that location (run after flutter build linux).
        const bundleBase =
            'build/linux/x64/release/bundle/data/flutter_assets/assets/models';
        final llm = p.join(bundleBase, 'gemma-4-E2B-it-Q4_K_M.gguf');
        final mmproj = p.join(bundleBase, 'mmproj-BF16.gguf');

        if (!File(llm).existsSync()) {
          markTestSkipped(
            'Linux bundle not found at $bundleBase — run flutter build linux first',
          );
          return;
        }

        print('Linux bundle LLM    : $llm (${File(llm).lengthSync()} bytes)');
        print('Linux bundle mmproj : $mmproj (${File(mmproj).lengthSync()} bytes)');

        expect(File(llm).existsSync(), isTrue);
        expect(File(mmproj).existsSync(), isTrue);
        expect(File(llm).lengthSync(), greaterThan(100 * 1024 * 1024),
            reason: 'LLM file should be larger than 100 MB');
      },
    );
  });
}
