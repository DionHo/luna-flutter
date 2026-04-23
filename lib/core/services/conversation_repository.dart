import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../error/app_exception.dart';
import '../models/message.dart';
import '../models/session.dart';

/// Persists [Session] and [ConversationTurn] records in a local SQLite database.
class ConversationRepository {
  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    try {
      final dir = await getApplicationSupportDirectory();
      final dbPath = p.join(dir.path, 'luna_conversation.db');
      _db = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Migrate from v1: drop old single-session table, create new schema.
            await db.execute('DROP TABLE IF EXISTS conversation_turns');
            await _createSchema(db);
          }
        },
      );
      return _db!;
    } catch (e) {
      throw DatabaseException('Failed to open conversation database: $e');
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE sessions (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE conversation_turns (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
        role       TEXT    NOT NULL,
        content    TEXT    NOT NULL,
        timestamp  INTEGER NOT NULL
      )
    ''');
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  /// Returns all sessions ordered newest first.
  Future<List<Session>> loadSessions() async {
    try {
      final db = await _getDb();
      final rows = await db.query('sessions', orderBy: 'id DESC');
      return rows.map(Session.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to load sessions: $e');
    }
  }

  /// Creates a new session and returns it with its assigned [id].
  Future<Session> createSession(String title) async {
    try {
      final db = await _getDb();
      final now = DateTime.now();
      final id = await db.insert('sessions', {
        'title': title,
        'created_at': now.millisecondsSinceEpoch,
      });
      return Session(id: id, title: title, createdAt: now);
    } catch (e) {
      throw DatabaseException('Failed to create session: $e');
    }
  }

  /// Deletes a session and all its turns.
  Future<void> deleteSession(int sessionId) async {
    try {
      final db = await _getDb();
      await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
    } catch (e) {
      throw DatabaseException('Failed to delete session: $e');
    }
  }

  // ── Turns ─────────────────────────────────────────────────────────────────

  /// Returns all turns for [sessionId] in insertion order.
  Future<List<ConversationTurn>> loadTurns(int sessionId) async {
    try {
      final db = await _getDb();
      final rows = await db.query(
        'conversation_turns',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'id ASC',
      );
      return rows.map(ConversationTurn.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Failed to load conversation turns: $e');
    }
  }

  /// Appends [turn] to [sessionId]. Returns the turn with its assigned [id].
  Future<ConversationTurn> addTurn(
    int sessionId,
    ConversationTurn turn,
  ) async {
    try {
      final db = await _getDb();
      final id = await db.insert('conversation_turns', {
        'session_id': sessionId,
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

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
