// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:get/get.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/models/chat_message.dart';
import 'package:roomy_finder/models/chat_user.dart';

class ChatConversation {
  final ChatUser other;
  ChatMessage? lastMessage;
  ChatConversation({required this.other, this.lastMessage});

  ChatUser get me => AppController.me.chatUser;
  static bool homeTabIsChat = false;
  static String? currrentChatKey;
  static void Function()? currrentChatOnTapCallBack;
  static final List<int> foregroudChatNotificationsIds = [];

  String get key => "${AppController.me.id}-${other.id}";

  bool haveUnreadMessage = false;

  Future<void> updateChatInfo() async {
    me.profilePicture = AppController.me.profilePicture;
    me.fcmToken = AppController.me.fcmToken;
    me.firstName = AppController.me.firstName;
    me.lastName = AppController.me.lastName;
    me.createdAt = AppController.me.createdAt;

    final friendInfo = await ApiService.getUserInfo(other.id);
    if (friendInfo != null) {
      other.profilePicture = '${friendInfo["profilePicture"]}';
      other.fcmToken = '${friendInfo["fcmToken"]}';
      other.firstName = '${friendInfo["firstName"]}';
      other.lastName = '${friendInfo["lastName"]}';
      other.createdAt =
          DateTime.tryParse('${friendInfo["createdAt"]}') ?? other.createdAt;
    }
  }

  static String createConvsertionKey(String myId, String friendId) {
    return "$myId-$friendId";
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'other': other.toMap(),
      'lastMessage': lastMessage!.toMap(),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      other: ChatUser.fromMap(map['other'] as Map<String, dynamic>),
      lastMessage: map['lastMessage'] != null
          ? ChatMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatConversation.fromJson(String source) =>
      ChatConversation.fromMap(json.decode(source) as Map<String, dynamic>);

  void updateLastMessage(ChatMessage message) => lastMessage = message;

  static List<ChatConversation> conversations = [];

  static void addConversation(ChatConversation conversation) {
    if (!conversations.contains(conversation)) {
      conversations.insert(0, conversation);
    }
  }

  static void addAllConversations(List<ChatConversation> conversations) {
    for (var conv in conversations) {
      if (!ChatConversation.conversations.contains(conv)) {
        ChatConversation.conversations.insert(0, conv);
      }
    }
  }

  static void removeConversation(ChatConversation conversation) {
    conversations.remove(conversation);
  }

  static ChatConversation? findConversation(String key) {
    return conversations.firstWhereOrNull((c) => c.key == key);
  }

  static void sortConversations() {
    conversations.sort((a, b) {
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return 1;

      return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
    });
  }

  @override
  bool operator ==(covariant ChatConversation other) {
    if (identical(this, other)) return true;

    return this.other == other.other && other.lastMessage == lastMessage;
  }

  @override
  int get hashCode => other.hashCode ^ lastMessage.hashCode;
}
