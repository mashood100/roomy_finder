// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter_chat_types/flutter_chat_types.dart' as flyer_types;
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

import 'package:roomy_finder/models/chat_user.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String recieverId;
  final String? bookingId;
  final String? roommateId;
  final String type;
  final String? body;
  final String? fileUri;
  final String? fileName;
  final int? fileSize;
  final String? replyId;
  final dynamic other;
  bool isRecieved;
  bool isRead;
  bool isDeletedForSender;
  bool isDeletedForReciever;
  DateTime? dateRecieved;
  DateTime? dateRead;
  final DateTime createdAt;

  ChatMessage? replyMessage;

  bool get isMine => senderId == AppController.me.id;

  ChatMessage? getRepliedMessage(List<ChatMessage> messages) {
    if (replyId == null) return null;
    return messages.firstWhereOrNull((e) => e.id == replyId);
  }

  flyer_types.Message getFlyerMessage(ChatUser author) {
    final flyAuthor = flyer_types.User(
      id: author.id,
      firstName: author.firstName,
      lastName: author.lastName,
      createdAt: author.createdAt.millisecondsSinceEpoch,
    );
    flyer_types.Status status;
    if (isRecieved) status = flyer_types.Status.delivered;
    if (isRead) {
      status = flyer_types.Status.seen;
    } else {
      status = flyer_types.Status.sent;
    }

    switch (type) {
      case "text":
        return flyer_types.TextMessage(
          id: id,
          author: flyAuthor,
          text: body ?? "",
          createdAt: createdAt.millisecondsSinceEpoch,
          status: status,
        );
      case "image":
        return flyer_types.ImageMessage(
          id: id,
          author: flyAuthor,
          name: fileName.toString(),
          uri: fileUri.toString(),
          size: fileSize ?? 0,
          createdAt: createdAt.millisecondsSinceEpoch,
          status: status,
        );
      case "video":
        return flyer_types.VideoMessage(
          id: id,
          author: flyAuthor,
          name: fileName.toString(),
          uri: fileUri.toString(),
          size: fileSize ?? 0,
          createdAt: createdAt.millisecondsSinceEpoch,
          status: status,
        );
      case "file":
        return flyer_types.FileMessage(
          id: id,
          author: flyAuthor,
          name: fileName.toString(),
          uri: fileUri.toString(),
          size: fileSize ?? 0,
          createdAt: createdAt.millisecondsSinceEpoch,
          status: status,
        );

      default:
        throw "Unsupported Message";
    }
  }

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recieverId,
    required this.bookingId,
    required this.roommateId,
    required this.type,
    required this.body,
    required this.fileUri,
    required this.fileName,
    required this.fileSize,
    required this.replyId,
    required this.other,
    required this.isRecieved,
    required this.isRead,
    required this.isDeletedForSender,
    required this.isDeletedForReciever,
    required this.dateRecieved,
    required this.dateRead,
    required this.createdAt,
  });

  ChatMessage.newTextMessage({
    required String id,
    required String senderId,
    required String recieverId,
    required String body,
    String? bookingId,
    String? roommateId,
    String? replyId,
    String? other,
  }) : this._fromNow(
          id: id,
          senderId: senderId,
          recieverId: recieverId,
          type: 'text',
          body: body,
          bookingId: bookingId,
          roommateId: roommateId,
          replyId: replyId,
          other: other,
        );

  ChatMessage.newImageMessage({
    required String id,
    required String senderId,
    required String recieverId,
    required String fileUri,
    required String fileName,
    required int fileSize,
    String? body,
    String? bookingId,
    String? roommateId,
    String? replyId,
    String? other,
  }) : this._fromNow(
          id: id,
          senderId: senderId,
          recieverId: recieverId,
          type: 'image',
          fileUri: fileUri,
          fileName: fileName,
          fileSize: fileSize,
          body: body,
          bookingId: bookingId,
          roommateId: roommateId,
          replyId: replyId,
          other: other,
        );

  ChatMessage.newVideoMessage({
    required String id,
    required String senderId,
    required String recieverId,
    required String fileUri,
    required String fileName,
    required int fileSize,
    String? body,
    String? bookingId,
    String? roommateId,
    String? replyId,
    String? other,
  }) : this._fromNow(
          id: id,
          senderId: senderId,
          recieverId: recieverId,
          type: 'video',
          fileUri: fileUri,
          fileName: fileName,
          fileSize: fileSize,
          body: body,
          bookingId: bookingId,
          roommateId: roommateId,
          replyId: replyId,
          other: other,
        );

  ChatMessage.newFileMessage({
    required String id,
    required String senderId,
    required String recieverId,
    required String fileUri,
    required String fileName,
    required int fileSize,
    String? body,
    String? bookingId,
    String? roommateId,
    String? replyId,
    String? other,
  }) : this._fromNow(
          id: id,
          senderId: senderId,
          recieverId: recieverId,
          type: 'file',
          fileUri: fileUri,
          fileName: fileName,
          fileSize: fileSize,
          body: body,
          bookingId: bookingId,
          roommateId: roommateId,
          replyId: replyId,
          other: other,
        );

  ChatMessage._fromNow({
    required this.id,
    required this.senderId,
    required this.recieverId,
    required this.type,
    this.bookingId,
    this.roommateId,
    this.body,
    this.fileUri,
    this.fileName,
    this.fileSize,
    this.replyId,
    this.other,
  })  : isRecieved = false,
        isRead = false,
        isDeletedForSender = false,
        isDeletedForReciever = false,
        dateRecieved = null,
        dateRead = null,
        createdAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'senderId': senderId,
      'recieverId': recieverId,
      'bookingId': bookingId,
      'roommateId': roommateId,
      'type': type,
      'body': body,
      'fileUri': fileUri,
      'fileName': fileName,
      'fileSize': fileSize,
      'replyId': replyId,
      'other': other,
      'isRecieved': isRecieved,
      'isRead': isRead,
      'isDeletedForSender': isDeletedForSender,
      'isDeletedForReciever': isDeletedForReciever,
      'dateRecieved': dateRecieved?.toIso8601String(),
      'dateRead': dateRead?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      recieverId: map['recieverId'] as String,
      bookingId: map['bookingId'] != null ? map['bookingId'] as String : null,
      roommateId:
          map['roommateId'] != null ? map['roommateId'] as String : null,
      type: map['type'] as String,
      body: map['body'] != null ? map['body'] as String : null,
      fileUri: map['fileUri'] != null ? map['fileUri'] as String : null,
      fileName: map['fileName'] != null ? map['fileName'] as String : null,
      fileSize: map['fileSize'] != null ? map['fileSize'] as int : null,
      replyId: map['replyId'] != null ? map['replyId'] as String : null,
      other: map['other'] as dynamic,
      isRecieved: map['isRecieved'] as bool,
      isRead: map['isRead'] as bool,
      isDeletedForSender: map['isDeletedForSender'] as bool,
      isDeletedForReciever: map['isDeletedForReciever'] as bool,
      dateRecieved: map['dateRecieved'] != null
          ? DateTime.parse(map['dateRecieved'] as String)
          : null,
      dateRead: map['dateRead'] != null
          ? DateTime.parse(map['dateRead'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ChatMessage other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  Future<void> markAsRead() async {
    isRecieved = true;
    dateRecieved ??= DateTime.now();
    isRead = true;
    dateRead ??= DateTime.now();
  }

  Future<void> markAsRecieved() async {
    isRecieved = true;
    dateRecieved ??= DateTime.now();
  }

  static Future<bool> deleteMessages(
    List<ChatMessage> messages,
    bool isDeletedForAll,
  ) async {
    try {
      final res = await ApiService.getDio.delete('/message', data: {
        "messageIds": messages.map((e) => e.id).toList(),
      });

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteConversation(ChatConversation conversation) async {
    try {
      final res = await ApiService.getDio.delete(
        '/message/conversations',
        data: {"otherId": conversation.other.id},
      );

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestMarkAsRead(
    String senderId,
    String recieverId,
  ) async {
    try {
      final res = await ApiService.getDio.put(
        '/messages/mark-as-read',
        data: {"senderId": senderId, "recieverId": recieverId},
      );

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestMarkAsRecieved(
    String senderId,
    String recieverId,
  ) async {
    try {
      final res = await ApiService.getDio.put(
        '/messages/mark-as-recieved',
        data: {"senderId": senderId, "recieverId": recieverId},
      );

      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// var x = 1 as flyer_types.Message;

// void main(List<String> args) {
//   x.status; var y = flyer_types.Status
// }
