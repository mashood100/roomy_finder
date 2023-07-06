// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/models/user.dart';

class ChatConversationV2 {
  final String key;
  final User first;
  final User second;
  final List<ChatMessageV2> messages;
  final DateTime createdAt;
  DateTime? updatedAt;
  final List<String> blocks;
  List<int> localNotificationsIds = [];

  // This is used to sent local notifications actions events.
  @pragma("vm:entry-point")
  static final _lnStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get localNotificationStream {
    return _lnStreamController.stream;
  }

  static String createKey(String first, String second) {
    if (first.compareTo(second) > 0) return "$second#$first";

    return "$first#$second";
  }

  static bool homeTabIsChat = false;

  /// Callback which is used to forward socket events in chat rooms
  static void Function(String event, dynamic data, String key)?
      onChatEventCallback;

  /// Called after any action notification from flutter local notifications
  static void onLocalNotificationsAction(Map<String, dynamic> payload) {
    _lnStreamController.add(payload);
  }

  int get unReadMessageCount {
    var count = 0;

    for (int i = messages.length - 1; i >= 0; i--) {
      var m = messages[i];

      if (!m.isMine) {
        if (!m.reads.contains(me.id)) {
          count++;
        } else {
          break;
        }
      }
    }

    return count;
  }

  User get me => AppController.me;
  User get other => !first.isMe ? first : second;

  bool get iAmBlocked {
    return blocks.any((e) => e == me.id);
  }

  bool get iHaveBlocked {
    return blocks.any((e) => e == other.id);
  }

  ChatMessageV2? get lastMessage => messages.isNotEmpty ? messages.last : null;

  ChatConversationV2({
    required this.key,
    required this.first,
    required this.second,
    required this.messages,
    DateTime? createdAt,
    this.updatedAt,
    required this.blocks,
  }) : createdAt = createdAt ?? DateTime.now();

  void markMyMessagesAsRead() {
    for (int i = messages.length - 1; i >= 0; i--) {
      var m = messages[i];

      if (m.isMine) {
        if (!m.reads.contains(other.id)) m.reads.add(other.id);
      }
    }
  }

  void markOthersMessagesAsRead() {
    for (int i = messages.length - 1; i >= 0; i--) {
      var m = messages[i];

      if (!m.isMine) {
        if (!m.reads.contains(me.id)) m.reads.add(me.id);
      }
    }
  }

  void markMyMessagesAsRecieved() {
    for (int i = messages.length - 1; i >= 0; i--) {
      var m = messages[i];

      if (m.isMine) {
        if (!m.recieveds.contains(other.id)) {
          m.recieveds.add(other.id);
        }
      }
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'first': first.toMap(),
      'second': second.toMap(),
      'messages': messages.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'blocks': blocks,
    };
  }

  factory ChatConversationV2.fromMap(Map<String, dynamic> map) {
    return ChatConversationV2(
      key: map['key'] as String,
      first: User.fromMap(map['first'] as Map<String, dynamic>),
      second: User.fromMap(map['second'] as Map<String, dynamic>),
      messages: List<ChatMessageV2>.from(
        (map['messages'] as List).map<ChatMessageV2>(
          (x) => ChatMessageV2.fromMap(x as Map<String, dynamic>),
        ),
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      blocks: List<String>.from(map['blocks'] as List),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatConversationV2.fromJson(String source) =>
      ChatConversationV2.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ChatConversationV2 other) {
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }

  void addMessages(List<ChatMessageV2> messages) {
    this.messages.addAll(messages);
  }

  void sortMessages() {
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
