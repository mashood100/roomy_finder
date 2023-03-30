import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/models/user.dart' as app_user;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ChatConversation {
  final app_user.User me;
  final app_user.User friend;
  final List<types.Message> messages;
  final DateTime createdAt;

  ChatConversation({
    required this.messages,
    required this.me,
    required this.friend,
    required this.createdAt,
  });

  static String get conversationsKey => "chat_conversations";

  /// This value is set went entered in a chat. This will be uses by
  /// the Notification controller.
  static String? currrentChatKey;

  ChatConversation.newConversation(this.me, this.friend)
      : createdAt = DateTime.now(),
        messages = [];

  String get key => "${conversationsKey}_${me.id}_${friend.id}";
  int get hasUreadMessages => messages.where((e) => false).length;

  void newMessage(types.Message msg) {
    if (messages.contains(msg)) messages.remove(msg);
    messages.insert(0, msg);
    saveChat();
  }

  static String createConvsertionKey(String myId, String friendId) {
    return "${conversationsKey}_${myId}_$friendId";
  }

  Future<void> updateChatInfo() async {
    final myInfo = await ApiService.getUserInfo(me.id);
    if (myInfo != null) {
      me.profilePicture = '${myInfo["profilePicture"]}';
      me.fcmToken = '${myInfo["fcmToken"]}';
    }

    final friendInfo = await ApiService.getUserInfo(friend.id);
    if (friendInfo != null) {
      friend.profilePicture = '${friendInfo["profilePicture"]}';
      friend.fcmToken = '${friendInfo["fcmToken"]}';
    }
  }

  Future<void> saveChat() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final file =
          File(path.join(directory.path, "conversations", "$key.json"));
      if (!(await file.exists())) {
        file.createSync(recursive: true);
      }

      await file.writeAsString(toJson());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  Future<bool> loadMessages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final file =
          File(path.join(directory.path, "conversations", "$key.json"));

      if (!file.existsSync()) return false;

      final content = file.readAsStringSync();

      final chat = ChatConversation.fromJson(content);

      messages.clear();
      messages.addAll(chat.messages);
      return true;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return false;
    }
  }

  Future<bool?> deleteChat() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final file =
          File(path.join(directory.path, "conversations", "$key.json"));

      if (file.existsSync()) file.deleteSync();

      return true;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return false;
    }
  }

  static Future<List<ChatConversation>> getAllSavedChats(String userId) async {
    final directory = await getApplicationDocumentsDirectory();

    final conversationDirectory =
        Directory(path.join(directory.path, "conversations"));

    final files = conversationDirectory.listSync().where((e) {
      return e.path.contains(userId);
    });

    final List<ChatConversation> conversations = [];

    for (var item in files) {
      try {
        if (path.extension(item.path) == ".json") {
          final file = File(item.path);
          final data = file.readAsStringSync();

          conversations.add(ChatConversation.fromJson(data));
        }
      } catch (_) {}
    }

    return conversations;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messages': messages.map((x) => x.toJson()).toList(),
      'me': me.toMap(),
      'friend': friend.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      messages: List<types.Message>.from(
        (map['messages'] as List).map<types.Message>(
          (x) => types.Message.fromJson(x as Map<String, dynamic>),
        ),
      ),
      me: app_user.User.fromMap(map['me'] as Map<String, dynamic>),
      friend: app_user.User.fromMap(map['friend'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() {
    return json.encode(toMap());
  }

  factory ChatConversation.fromJson(String source) =>
      ChatConversation.fromMap(json.decode(source) as Map<String, dynamic>);
}
