import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nobodywho/nobodywho.dart';
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

  // NobodyWho.init() sets up the native llama.cpp library (flutter_rust_bridge).
  // Track success explicitly — if it fails the native Rust bridge is unavailable
  // and any subsequent call to nobodywho functions will throw
  // "flutter_rust_bridge has not been initialized".  We must NOT attempt model
  // loading in that case, but we still want the rest of the app to work.
  bool nobodywhoReady = false;
  try {
    await NobodyWho.init();
    nobodywhoReady = true;
  } catch (e) {
    debugPrint('NobodyWho.init() failed — AI engine unavailable: $e');
  }

  // Resolve bundled model paths.  Failures are non-fatal: the chat screen
  // shows a placeholder message when the model is unavailable.
  final bootstrap = ModelBootstrapService();
  if (nobodywhoReady) {
    try {
      await bootstrap.init();
    } catch (_) {
      // Model files not present (e.g. dev build without download_models.sh).
    }
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

