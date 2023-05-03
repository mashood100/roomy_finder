import 'dart:convert';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/models/chat_message.dart';
import 'package:roomy_finder/models/chat_user.dart';

class ChatConversation {
  final ChatUser other;
  ChatMessage? lastMessage;
  ChatConversation({required this.other, this.lastMessage});

  ChatUser get me => AppController.me.chatUser;
  static String? currrentChatKey;
  static void Function()? currrentChatOnTapCallBack;

  String get key => "${AppController.me.id}-${other.id}";

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

  @override
  bool operator ==(covariant ChatConversation other) {
    if (identical(this, other)) return true;

    return other.key == key;
  }

  @override
  int get hashCode => other.hashCode ^ lastMessage.hashCode;
}
