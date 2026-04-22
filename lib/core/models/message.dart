/// A single message turn in a conversation.
class ConversationTurn {
  const ConversationTurn({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ConversationTurn.fromMap(Map<String, Object?> map) {
    return ConversationTurn(
      id: map['id'] as int,
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  final int id;

  /// Either `'user'` or `'assistant'`.
  final String role;

  final String content;
  final DateTime timestamp;

  Map<String, Object?> toMap() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  ConversationTurn copyWith({String? content}) {
    return ConversationTurn(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
    );
  }
}
