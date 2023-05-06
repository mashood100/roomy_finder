import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:roomy_finder/controllers/app_controller.dart';

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

  static Future<List<AppNotication>> getSavedNotifications() async {
    try {
      final notifications = <AppNotication>[];

      final pref = await SharedPreferences.getInstance();

      final key = "${AppController.me.id}notifications";

      final notificationsJson = pref.getStringList(key) ?? [];

      for (final n in notificationsJson) {
        notifications.add(AppNotication.fromJson(n));
      }

      return notifications;
    } catch (e) {
      debugPrint('$e');
      return [];
    }
  }

  static Future<bool> deleteNotifications(AppNotication notication) async {
    try {
      final pref = await SharedPreferences.getInstance();

      final key = "${AppController.me.id}notifications";

      var notificationsJson = pref.getStringList(key) ?? [];

      notificationsJson.remove(notication.toJson());

      pref.setStringList(key, notificationsJson);
      return true;
    } catch (e) {
      debugPrint('$e');
      return false;
    }
  }

  // User to be user fo saving notification
  static User? currentUser;
}
