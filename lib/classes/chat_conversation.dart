// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/models/chat_message.dart';
import 'package:roomy_finder/models/chat_user.dart';

class ChatConversation {
  final ChatUser me;
  final ChatUser friend;
  final DateTime createdAt;
  ChatMessage? lastMessage;
  final int unReadMessagesCount;

  ChatConversation({
    required this.me,
    required this.friend,
    required this.createdAt,
    required this.lastMessage,
    this.unReadMessagesCount = 0,
  });

  /// This value is set went entered in a chat. This will be uses by
  /// the Notification controller.
  static String? currrentChatKey;
  static void Function()? currrentChatOnTapCallBack;

  ChatConversation.newConversation({
    required this.me,
    required this.friend,
    this.lastMessage,
    this.unReadMessagesCount = 0,
  }) : createdAt = DateTime.now();

  String get key => "${me.id}-${friend.id}";

  static String createConvsertionKey(String myId, String friendId) {
    return "$myId-$friendId";
  }

  Future<void> updateChatInfo() async {
    me.profilePicture = AppController.me.profilePicture;
    me.fcmToken = AppController.me.fcmToken;
    me.firstName = AppController.me.firstName;
    me.lastName = AppController.me.lastName;
    me.createdAt = AppController.me.createdAt;

    final friendInfo = await ApiService.getUserInfo(friend.id);
    if (friendInfo != null) {
      friend.profilePicture = '${friendInfo["profilePicture"]}';
      friend.fcmToken = '${friendInfo["fcmToken"]}';
      friend.firstName = '${friendInfo["firstName"]}';
      friend.lastName = '${friendInfo["lastName"]}';
      friend.createdAt =
          DateTime.tryParse('${friendInfo["createdAt"]}') ?? friend.createdAt;
    }
  }

  Future<void> saveChat() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final file = File(path.join(directory.path, "chats" "${me.id}.json"));

      final chats = <ChatConversation>[];

      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          chats.addAll((json.decode(content) as List).map((e) {
            return ChatConversation.fromJson(e);
          }).where((e) => e != this));
        }
      } else {
        file.createSync(recursive: true);
      }

      chats.insert(0, this);

      await file
          .writeAsString(jsonEncode(chats.map((e) => e.toJson()).toList()));
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  Future<List<ChatMessage>> loadMessages() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(path.join(directory.path, "messages", "$key.json"));

    if (!file.existsSync()) return [];

    final content = file.readAsStringSync();

    final messages = <ChatMessage>[];
    if (content.isNotEmpty) {
      messages.addAll((json.decode(content) as List).map((e) {
        return ChatMessage.fromJson(e);
      }));
    }

    return messages;
  }

  Future<bool?> deleteChat() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final file = File(path.join(directory.path, "chats" "${me.id}.json"));

      if (file.existsSync()) {
        final content = file.readAsStringSync();

        if (content.isNotEmpty) {
          final chats = (json.decode(content) as List).map((e) {
            return ChatConversation.fromJson(e);
          }).where((e) => e != this);

          await file
              .writeAsString(jsonEncode(chats.map((e) => e.toJson()).toList()));
        }
        return true;
      } else {
        return false;
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return false;
    }
  }

  static Future<List<ChatConversation>> getAllSavedChats(String userId) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(path.join(directory.path, "chats" "$userId.json"));

    if (!file.existsSync()) return [];

    final content = file.readAsStringSync();

    return (json.decode(content) as List)
        .map((e) => ChatConversation.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'me': me.toMap(),
      'friend': friend.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessage': lastMessage?.toMap(),
      'unReadMessagesCount': unReadMessagesCount,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      me: ChatUser.fromMap(map['me'] as Map<String, dynamic>),
      friend: ChatUser.fromMap(map['friend'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastMessage: map['lastMessage'] != null
          ? ChatMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      unReadMessagesCount: map['unReadMessagesCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatConversation.fromJson(String source) =>
      ChatConversation.fromMap(json.decode(source) as Map<String, dynamic>);

  // void markMessagesAsRead(DateTime startDate) {
  //   for (var i = messages.length - 1; i >= 0; i--) {
  //     final m = messages[i];
  //     if (m.createdAt.isBefore(startDate)) {
  //       m.isRecieved = true;
  //       m.isRead = true;
  //     } else {
  //       break;
  //     }
  //   }

  //   saveChat();
  // }

  // void markMessageAsRecieved(ChatMessage message) {
  //   final m = messages.firstWhereOrNull((e) => e == message);
  //   m?.isRecieved = true;
  //   saveChat();
  // }

  static Future<List<ChatMessage>> fetchMessages(DateTime? lastDate) async {
    final query = <String, dynamic>{};

    if (lastDate != null) query["lastDate"] = lastDate.toIso8601String();

    final res = await ApiService.getDio.get(
      '/messages',
      queryParameters: query,
    );

    if (res.statusCode == 200) {
      final list =
          (res.data as List).map((e) => ChatMessage.fromMap(e)).toList();

      return list;
    } else {
      throw Exception(
          "Failed to get messages with status code of ${res.statusCode}");
    }
  }

  @override
  bool operator ==(covariant ChatConversation other) {
    if (identical(this, other)) return true;

    return key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}
