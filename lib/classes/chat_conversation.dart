// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/models/message.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatConversation {
  final List<Message> messages;
  final User me;
  final User friend;
  final DateTime createdAt;

  ChatConversation({
    required this.messages,
    required this.me,
    required this.friend,
    required this.createdAt,
  });

  static String get conversationsKey =>
      "${AppController.me.id}-chat-conversations-keys";

  ChatConversation.newConversation({required this.friend})
      : me = AppController.me,
        createdAt = DateTime.now(),
        messages = [];

  String get key => "$conversationsKey${me.id}#${friend.id}";
  int get hasUreadMessages => messages.where((e) => e.isRead == false).length;

  void newMessageFromContent(String content, bool byMe) {
    final msg = Message.fomNow(content: content, sender: byMe ? me : friend);

    if (!messages.contains(msg)) {
      messages.add(msg);
      saveChat();
      addUserConversationKeyToStorage(key);
    }
  }

  // void newMessage(Message msg) {
  //   if (!messages.contains(msg)) {
  //     messages.add(msg);
  //     saveChat();
  //     addUserConversationKeyToStorage(key);
  //   }
  // }

  static String createConvsertionKey(String myId, String frienId) {
    return "$conversationsKey$myId#$frienId";
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
      final pref = await SharedPreferences.getInstance();
      pref.setString(key, toJson());
    } catch (e) {
      Get.log("e");
    }
  }

  static Future<ChatConversation?> getSavedChat(String key) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final source = pref.getString(key);
      if (source == null) return null;
      return ChatConversation.fromJson(source);
    } catch (e) {
      Get.log("e");
      return null;
    }
  }

  static Future<bool?> removeSavedChat(String key) async {
    try {
      final pref = await SharedPreferences.getInstance();
      pref.remove(key);
      return true;
    } catch (e) {
      Get.log("e");
      return false;
    }
  }

  static Future<void> addUserConversationKeyToStorage(String key) async {
    final pref = await SharedPreferences.getInstance();
    final keys = pref.getStringList(conversationsKey) ?? [];
    if (!keys.contains(key)) {
      keys.insert(0, key);
      pref.setStringList(conversationsKey, keys);
    }
  }

  static Future<List<String>> getUserConversationKeyToStorage() async {
    final pref = await SharedPreferences.getInstance();
    final keys = pref.getStringList(conversationsKey) ?? [];
    return keys;
  }

  static Future<List<ChatConversation>> getAllSavedChats() async {
    final keys = await getUserConversationKeyToStorage();

    final List<ChatConversation> result = [];

    for (var key in keys) {
      final data = await ChatConversation.getSavedChat(key);
      if (data != null) result.add(data);
    }
    return result;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messages': messages.map((x) => x.toMap()).toList(),
      'me': me.toMap(),
      'friend': friend.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      messages: List<Message>.from(
        (map['messages'] as List).map<Message>(
          (x) => Message.fromMap(x as Map<String, dynamic>),
        ),
      ),
      me: User.fromMap(map['me'] as Map<String, dynamic>),
      friend: User.fromMap(map['friend'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatConversation.fromJson(String source) =>
      ChatConversation.fromMap(json.decode(source) as Map<String, dynamic>);
}
