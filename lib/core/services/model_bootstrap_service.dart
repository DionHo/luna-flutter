import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../error/app_exception.dart';

/// Locates the bundled GGUF model files from the app's asset bundle.
///
/// On desktop (Linux / Windows), Flutter bundles assets as regular files
/// inside `data/flutter_assets/` next to the executable.  The paths are
/// resolved from [Platform.resolvedExecutable] — no in-memory extraction is
/// needed, which keeps peak RAM usage low for the 3+ GB model files.
///
/// Call [init] once at startup.  After a successful [init], [llmPath] and
/// [mmprojPath] are safe to read.
class ModelBootstrapService {
  static const _llmAssetKey =
      'assets/models/gemma-4-E2B-it-Q4_K_M.gguf';
  static const _mmprojAssetKey = 'assets/models/mmproj-BF16.gguf';

  String? _llmPath;
  String? _mmprojPath;

  /// Absolute path to the main LLM GGUF file.
  String get llmPath => _llmPath!;

  /// Absolute path to the multimodal projection model GGUF file.
  String get mmprojPath => _mmprojPath!;

  bool get isReady => _llmPath != null;

  /// Resolves model paths from the bundle and verifies the files exist.
  ///
  /// Throws [ModelLoadException] if the platform is not supported or the
  /// model files are missing (i.e. [scripts/download_models.sh] was not run
  /// before building).
  Future<void> init() async {
    final isDesktop = defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (!isDesktop) {
      throw const ModelLoadException(
        'Automatic model bootstrap is only supported on desktop platforms '
        '(Linux, Windows, macOS).  Mobile support is not yet implemented.',
      );
    }

    final exeDir = path.dirname(Platform.resolvedExecutable);
    final llm =
        path.join(exeDir, 'data', 'flutter_assets', _llmAssetKey);
    final mmproj =
        path.join(exeDir, 'data', 'flutter_assets', _mmprojAssetKey);

    if (!File(llm).existsSync()) {
      throw ModelLoadException(
        'LLM model not found: $llm\n'
        'Run scripts/download_models.sh before building the app.',
      );
    }
    if (!File(mmproj).existsSync()) {
      throw ModelLoadException(
        'Projection model not found: $mmproj\n'
        'Run scripts/download_models.sh before building the app.',
      );
    }

    _llmPath = llm;
    _mmprojPath = mmproj;
  }
}
