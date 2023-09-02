// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:get/utils.dart';
import 'package:isar/isar.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/models/user/user.dart';

import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/utilities/isar.dart';

part 'chat_conversation_v2.g.dart';

@Collection()
class ChatConversationV2 {
  static bool messagesAreSync = false;
  static String? currentChatRoomKey;
  static final messagesNotificationIds = <int>[];

  Id get isarId => fastHash(key);

  @Index(unique: true, replace: true)
  final String key;

  final first = IsarLink<User>();

  final second = IsarLink<User>();

  final DateTime createdAt;
  List<String> blocks;

  final lastMessage = IsarLink<ChatMessageV2>();

  int unReadMessageCount = 0;

  @ignore
  User get me {
    var user = first.value?.isMe != true ? second.value : first.value;
    return user ?? User.GUEST_USER;
  }

  @ignore
  User get other {
    var user = first.value?.isMe == true ? second.value : first.value;
    return user ?? User.GUEST_USER;
  }

  @ignore
  bool get iAmBlocked {
    return blocks.any((e) => e == me.id);
  }

  @ignore
  bool get iHaveBlocked {
    return blocks.any((e) => e == other.id);
  }

  ChatConversationV2({
    required this.key,
    required this.blocks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'first': first.value!.toMap(),
      'second': second.value!.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'blocks': blocks,
      'lastMessage': lastMessage.value,
    };
  }

  factory ChatConversationV2.fromMap(Map<String, dynamic> map) {
    var chat = ChatConversationV2(
      key: map['key'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      blocks: List<String>.from(map['blocks'] as List),
    );

    final first = User.fromMap(map['first'] as Map<String, dynamic>);

    final second = User.fromMap(map['second'] as Map<String, dynamic>);

    final lastMessage =
        ChatMessageV2.fromMap(map['lastMessage'] as Map<String, dynamic>);

    chat.first.value = first;
    chat.second.value = second;
    chat.lastMessage.value = lastMessage;

    return chat;
  }

  String toJson() => json.encode(toMap());

  factory ChatConversationV2.fromJson(String source) =>
      ChatConversationV2.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ChatConversationV2 other) {
    return other.key == key;
  }

  @ignore
  @override
  int get hashCode {
    return key.hashCode;
  }

  Future<void> updateUserProfiles() async {
    try {
      final u1 = await ApiService.fetchUser(first.value!.id);
      if (u1 != null) {
        first.value = u1;

        await ISAR.writeTxn(() => ISAR.users.put(u1));
      }

      final u2 = await ApiService.fetchUser(second.value!.id);
      if (u2 != null) {
        second.value = u2;

        await ISAR.writeTxn(() => ISAR.users.put(u2));
      }
    } catch (e) {
      Get.log("$e");
    }
  }

  static String createKey(String first, String second) {
    if (first.compareTo(second) > 0) return "$second#$first";

    return "$first#$second";
  }

/*  // This is used to sent local notifications actions events.
  @pragma("vm:entry-point")
  static final _lnStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get localNotificationStream {
    return _lnStreamController.stream;
  }

  

  static bool homeTabIsChat = false;

  /// Callback which is used to forward socket events in chat rooms
  static void Function(String event, dynamic data, String key)?
      onChatEventCallback;

  /// Called after any action notification from flutter local notifications
  static void onLocalNotificationsAction(Map<String, dynamic> payload) {
    _lnStreamController.add(payload);
  }
*/
}
