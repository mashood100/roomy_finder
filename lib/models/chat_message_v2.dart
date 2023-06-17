import 'dart:convert';

import 'package:roomy_finder/controllers/app_controller.dart';

class ChatMessageV2 {
  String id;
  String senderId;
  String recieverId;
  String type;
  String? content;
  List<Map<String, dynamic>> recieveds;
  List<Map<String, dynamic>> reads;
  List<Map<String, dynamic>> deletes;
  bool isDeletedForAll;
  DateTime createdAt;
  String? replyId;
  Map<String, dynamic>? event;

  ChatMessageV2({
    required this.id,
    required this.senderId,
    required this.recieverId,
    required this.type,
    this.content,
    required this.recieveds,
    required this.reads,
    required this.deletes,
    required this.isDeletedForAll,
    required this.createdAt,
    this.replyId,
    this.event,
  });

  bool get isMine => senderId == AppController.me.id;
  bool get isRecieved => recieveds.isNotEmpty;
  bool get isRead => reads.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'senderId': senderId,
      'recieverId': recieverId,
      'type': type,
      'content': content,
      'recieveds': recieveds,
      'reads': reads,
      'deletes': deletes,
      'isDeletedForAll': isDeletedForAll,
      'createdAt': createdAt.toIso8601String(),
      'replyId': replyId,
      'event': event,
    };
  }

  factory ChatMessageV2.fromMap(Map<String, dynamic> map) {
    return ChatMessageV2(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      recieverId: map['recieverId'] as String,
      type: map['type'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      recieveds: List<Map<String, dynamic>>.from((map['recieveds'] as List)),
      reads: List<Map<String, dynamic>>.from((map['reads'] as List)),
      deletes: List<Map<String, dynamic>>.from((map['deletes'] as List)),
      isDeletedForAll: map['isDeletedForAll'] == true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      replyId: map['replyId'] != null ? map['replyId'] as String : null,
      event: map['event'] != null
          ? Map<String, dynamic>.from((map['event']))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessageV2.fromJson(String source) =>
      ChatMessageV2.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatMessageV2(id: $id, type: $type, content: $content)';
  }

  @override
  bool operator ==(covariant ChatMessageV2 other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
