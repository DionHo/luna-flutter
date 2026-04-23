import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../error/app_exception.dart';
import '../models/message.dart';

/// Persists [ConversationTurn] records in a local SQLite database.
class ConversationRepository {
  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    try {
      final dir = await getApplicationSupportDirectory();
      final dbPath = p.join(dir.path, 'luna_conversation.db');
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE conversation_turns (
              id        INTEGER PRIMARY KEY AUTOINCREMENT,
              role      TEXT    NOT NULL,
              content   TEXT    NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
        },
      );
      return _db!;
    } catch (e) {
      throw DatabaseException('Failed to open conversation database: $e');
    }
  }

  /// Returns all stored turns in insertion order.
  Future<List<ConversationTurn>> loadHistory() async {
    try {
      final db = await _getDb();
      final rows = await db.query('conversation_turns', orderBy: 'id ASC');
      return rows.map(ConversationTurn.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to load conversation history: $e');
    }
  }

  /// Appends [turn] to the database.  Returns the turn with its assigned [id].
  Future<ConversationTurn> addTurn(ConversationTurn turn) async {
    try {
      final db = await _getDb();
      final id = await db.insert('conversation_turns', {
        'role': turn.role,
        'content': turn.content,
        'timestamp': turn.timestamp.millisecondsSinceEpoch,
      });
      return ConversationTurn(
        id: id,
        role: turn.role,
        content: turn.content,
        timestamp: turn.timestamp,
      );
    } catch (e) {
      throw DatabaseException('Failed to persist conversation turn: $e');
    }
  }

  /// Deletes all stored turns.
  Future<void> clearHistory() async {
    try {
      final db = await _getDb();
      await db.delete('conversation_turns');
    } catch (e) {
      throw DatabaseException('Failed to clear conversation history: $e');
    }
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
