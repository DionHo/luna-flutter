import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Writes a startup diagnostics log to a file next to the executable.
///
/// Designed for production use:
/// - Appends to `luna_startup.log` (keeps the last [_maxBytes] bytes).
/// - No-ops silently on mobile / web (where file access is restricted).
/// - Never throws — log write failures are swallowed.
///
/// Usage:
/// ```dart
/// final log = StartupLogger();
/// log.add('NobodyWho.init() OK');
/// log.add('bootstrap.isReady: true');
/// await log.flush();
/// ```
class StartupLogger {
  static const int _maxBytes = 128 * 1024; // keep last 128 KB
  static const String _filename = 'luna_startup.log';

  final StringBuffer _buf = StringBuffer();

  /// Whether file logging is available on this platform.
  static bool get _supported =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Appends a timestamped line to the in-memory buffer.
  void add(String message) {
    final ts = DateTime.now().toIso8601String();
    _buf.writeln('$ts  $message');
    debugPrint('[StartupLogger] $message');
  }

  /// The path of the log file, or null if not supported.
  static String? get logFilePath {
    if (!_supported) return null;
    return p.join(p.dirname(Platform.resolvedExecutable), _filename);
  }

  /// Flushes the in-memory buffer to disk.
  ///
  /// Appends to the existing file and trims it to [_maxBytes] so the file
  /// never grows unbounded.  All IO errors are caught silently.
  Future<void> flush() async {
    if (!_supported) return;
    try {
      final file = File(logFilePath!);
      await file.parent.create(recursive: true);

      // Append new content.
      await file.writeAsString(_buf.toString(),
          mode: FileMode.append, flush: true);

      // Trim to last _maxBytes to prevent unbounded growth.
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) {
        final trimmed = bytes.sublist(bytes.length - _maxBytes);
        await file.writeAsBytes(trimmed, flush: true);
      }
    } catch (e) {
      debugPrint('StartupLogger: failed to write log: $e');
    }
  }
}
