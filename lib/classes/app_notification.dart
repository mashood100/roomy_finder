import 'dart:convert';

import 'package:roomy_finder/models/user.dart';
import 'package:uuid/uuid.dart';

class AppNotication {
  final String id;
  final String message;
  final String event;
  final DateTime createdAt;
  final bool isRead;

  AppNotication({
    required this.id,
    required this.message,
    required this.event,
    required this.createdAt,
    required this.isRead,
  });

  AppNotication.fromNow({
    required this.message,
    required this.event,
    required this.isRead,
  })  : createdAt = DateTime.now(),
        id = const Uuid().v4();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'event': event,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory AppNotication.fromMap(Map<String, dynamic> map) {
    return AppNotication(
      id: map['id'] as String,
      message: map['message'] as String,
      event: map['event'] as String,
      isRead: map['isRead'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotication.fromJson(String source) =>
      AppNotication.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'AppNotication(message: $message, event: $event, createdAt: $createdAt)';

  @override
  bool operator ==(covariant AppNotication other) {
    if (identical(this, other)) return true;
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // User to be user fo saving notification
  static User? currentUser;
}
