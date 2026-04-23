import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nobodywho/nobodywho.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/services/model_bootstrap_service.dart';
import 'features/chat/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite on Windows and Linux desktop requires the FFI implementation.
  // On Android and iOS the default factory is already set by the sqflite plugin.
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ── Diagnostic log ──────────────────────────────────────────────────────
  // On Windows release builds there is no console, so debug output is written
  // to luna_debug.log next to luna_flutter.exe.
  // Delete or ignore this file on production deployments.
  final log = StringBuffer();
  log.writeln('Luna debug log — ${DateTime.now().toIso8601String()}');
  log.writeln('OS      : ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  log.writeln('Exe     : ${Platform.resolvedExecutable}');
  log.writeln('ExeDir  : ${p.dirname(Platform.resolvedExecutable)}');
  log.writeln();

  // NobodyWho.init() sets up the native llama.cpp library (flutter_rust_bridge).
  // Track success explicitly — if it fails the native Rust bridge is unavailable
  // and any subsequent call to nobodywho functions will throw
  // "flutter_rust_bridge has not been initialized".  We must NOT attempt model
  // loading in that case, but we still want the rest of the app to work.
  bool nobodywhoReady = false;
  try {
    await NobodyWho.init();
    nobodywhoReady = true;
    log.writeln('[OK]   NobodyWho.init() succeeded');
  } catch (e, st) {
    log.writeln('[FAIL] NobodyWho.init() threw: $e');
    log.writeln('       Stack: $st');
    debugPrint('NobodyWho.init() failed — AI engine unavailable: $e');
  }

  // Resolve bundled model paths.  Failures are non-fatal: the chat screen
  // shows a placeholder message when the model is unavailable.
  final bootstrap = ModelBootstrapService();
  if (nobodywhoReady) {
    // Log the paths that will be checked regardless of success/failure.
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final llmPath = p.join(exeDir, 'data', 'flutter_assets', 'assets',
        'models', 'gemma-4-E2B-it-Q4_K_M.gguf');
    final mmprojPath = p.join(
        exeDir, 'data', 'flutter_assets', 'assets', 'models', 'mmproj-BF16.gguf');
    log.writeln('[INFO] LLM path    : $llmPath');
    log.writeln('[INFO] LLM exists  : ${File(llmPath).existsSync()}');
    log.writeln('[INFO] mmproj path : $mmprojPath');
    log.writeln('[INFO] mmproj exists: ${File(mmprojPath).existsSync()}');

    try {
      await bootstrap.init();
      log.writeln('[OK]   bootstrap.init() succeeded');
    } catch (e, st) {
      log.writeln('[FAIL] bootstrap.init() threw: $e');
      log.writeln('       Stack: $st');
      // Model files not present (e.g. dev build without download_models.sh).
    }
  } else {
    log.writeln('[SKIP] bootstrap.init() skipped — NobodyWho not ready');
  }

  log.writeln();
  log.writeln('bootstrap.isReady: ${bootstrap.isReady}');

  // Write log to file next to the executable (works even without a console).
  try {
    final logFile = File(p.join(p.dirname(Platform.resolvedExecutable), 'luna_debug.log'));
    await logFile.writeAsString(log.toString());
  } catch (e) {
    debugPrint('Could not write luna_debug.log: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        modelBootstrapProvider.overrideWithValue(bootstrap),
      ],
      child: const LunaApp(),
    ),
  );
}

