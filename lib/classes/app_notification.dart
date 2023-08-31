import 'dart:convert';

import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:uuid/uuid.dart';

class AppNotification {
  final String id;
  final String message;
  final String event;
  final String? title;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.event,
    this.title,
    required this.createdAt,
    required this.isRead,
  });

  AppNotification.fromNow({
    required this.message,
    required this.event,
    this.title,
    required this.isRead,
  })  : createdAt = DateTime.now(),
        id = const Uuid().v4();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'title': title,
      'event': event,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      message: map['message'] as String,
      title: map['title'] as String?,
      event: map['event'] as String,
      isRead: map['isRead'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppNotication(message: $message, event: $event, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant AppNotification other) {
    if (identical(this, other)) return true;
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  Future<bool> markAsRead(String userId) async {
    return NotificationController.markNotificationAsRead(userId, this);
  }
}
