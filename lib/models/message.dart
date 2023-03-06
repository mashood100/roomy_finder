// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/user.dart';

class Message {
  final String content;
  final User sender;
  final DateTime createdAt;
  bool isRead;

  Message({
    required this.content,
    required this.sender,
    required this.createdAt,
    this.isRead = false,
  });

  Message.fomNow({
    required this.content,
    required this.sender,
    this.isRead = false,
  }) : createdAt = DateTime.now();

  bool get sentByMe => sender.isMe;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'sender': sender.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      content: map['content'] as String,
      sender: User.fromMap(map['sender'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Message(content: $content, sender: $sender, createdAt: $createdAt)';

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.content == content &&
        other.sender == sender &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => content.hashCode ^ sender.hashCode ^ createdAt.hashCode;
}
