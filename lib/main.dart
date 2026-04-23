import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nobodywho/nobodywho.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite on Windows and Linux desktop requires the FFI implementation.
  // On Android and iOS the default factory is already set by the sqflite plugin.
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // NobodyWho.init() sets up the native llama.cpp library.  It is safe to
  // continue without it — the chat provider will show a "no model loaded"
  // placeholder when sendMessage is called with no model file configured.
  try {
    await NobodyWho.init();
  } catch (_) {
    // Ignore: the app works in stub mode until the user picks a model.
  }
  runApp(const ProviderScope(child: LunaApp()));
}

