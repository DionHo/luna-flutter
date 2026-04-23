/// A named conversation session.
class Session {
  const Session({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory Session.fromMap(Map<String, Object?> map) {
    return Session(
      id: map['id'] as int,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  final int id;
  final String title;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  Session copyWith({String? title}) {
    return Session(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
    );
  }
}
