// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:get/get.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/models/user.dart';

class ChatConversationV2 {
  final User other;
  ChatMessageV2? lastMessage;

  ChatConversationV2({
    required this.other,
    this.lastMessage,
  });

  User get me => AppController.me;
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

  static List<ChatConversationV2> conversations = [];

  static void addConversation(ChatConversationV2 conversation) {
    if (!conversations.contains(conversation)) {
      conversations.insert(0, conversation);
    }
  }

  static void addAllConversations(List<ChatConversationV2> conversations) {
    for (var conv in conversations) {
      if (!ChatConversationV2.conversations.contains(conv)) {
        ChatConversationV2.conversations.insert(0, conv);
      }
    }
  }

  static void removeConversation(ChatConversationV2 conversation) {
    conversations.remove(conversation);
  }

  static ChatConversationV2? findConversation(String key) {
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
  bool operator ==(covariant ChatConversationV2 other) {
    if (identical(this, other)) return true;

    return this.other == other.other && other.lastMessage == lastMessage;
  }

  @override
  int get hashCode => other.hashCode ^ lastMessage.hashCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'other': other.toMap(),
      'lastMessage': lastMessage?.toMap(),
    };
  }

  factory ChatConversationV2.fromMap(Map<String, dynamic> map) {
    return ChatConversationV2(
      other: User.fromMap(map['other'] as Map<String, dynamic>),
      lastMessage: map['lastMessage'] != null
          ? ChatMessageV2.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatConversationV2.fromJson(String source) =>
      ChatConversationV2.fromMap(json.decode(source) as Map<String, dynamic>);
}
