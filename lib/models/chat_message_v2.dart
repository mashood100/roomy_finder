// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:roomy_finder/classes/file_helprer.dart';

import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/utilities/data.dart';

class ChatMessageV2 {
  String id;
  String senderId;
  String recieverId;
  String type;
  String? content;
  List<String> recieveds;
  List<String> reads;
  List<String> deletes;
  bool isDeletedForAll;
  DateTime createdAt;
  String? replyId;
  String? bookingId;
  String? roommateId;
  Map<String, dynamic>? event;
  Map<String, dynamic>? voice;
  List<ChatFile> files;
  bool isSending;

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
    this.bookingId,
    this.roommateId,
    required this.isSending,
    this.event,
    this.voice,
    required this.files,
  }) {
    if (voice != null && voice!["bytes"] != null) {
      try {
        final bytes = voice!["bytes"] as Map<String, dynamic>;

        voiceFile = Uint8List.fromList(List<int>.from(bytes["data"]));
      } catch (e, trace) {
        Get.log("Voice file reading failed");
        Get.log("$e");
        Get.log("$trace");
      }
    }
  }

  bool get isMine => senderId == AppController.me.id;

  bool get isRecieved => isRead || recieveds.contains(recieverId);
  bool get isRead => reads.contains(recieverId);
  bool get isDeleted =>
      deletes.contains(AppController.me.id) || isDeletedForAll;

  bool get isVoice => type == "voice";

  String get typedMessage {
    if (voiceFile != null) {
      var min = voiceMinutues.toString().padLeft(2, "0");
      var sec = voiceSeconds.toString().padLeft(2, "0");

      var text1 = voiceMinutues! > 0 ? "$min Min :" : "";

      return "Sent a voice Note ($text1 $sec Sec)";
    }
    return "Sent a $type";
  }

  Uint8List? voiceFile;

  int? get voiceMinutues {
    if (voice != null && voice!["seconds"] is int) {
      var i = voice!["seconds"] as int;
      return i ~/ 60;
    }
    return null;
  }

  int? get voiceSeconds {
    if (voice != null && voice!["seconds"] is int) {
      var i = voice!["seconds"] as int;
      return i - (i ~/ 60);
    }
    return null;
  }

  void addDeletes(String userId, [DateTime? date]) {
    if (deletes.any((e) => e == userId)) return;
    deletes.add(userId);

    if (userId == AppController.me.id) {
      FileHelper.deleteFiles(files.map((e) => e.url).toList());
    }
  }

  Map<String, dynamic> createLocalNotificationPayload(String key,
      [String? event]) {
    return <String, String>{
      'key': key,
      'event': event ?? "new-message-v2",
      'messageId': id,
      'recieverId': recieverId,
      'senderId': senderId,
    };
  }

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
      'bookingId': bookingId,
      'roommateId': roommateId,
      'event': event,
      'isSending': isSending,
      'voice': voice,
      'files': files.map((x) => x.toMap()).toList(),
    };
  }

  factory ChatMessageV2.fromMap(Map<String, dynamic> map) {
    return ChatMessageV2(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      recieverId: map['recieverId'] as String,
      type: map['type'] as String,
      content: map['content'] != null ? map['content'] as String : null,
      recieveds: List<String>.from((map['recieveds'] as List)),
      reads: List<String>.from((map['reads'] as List)),
      deletes: List<String>.from((map['deletes'] as List)),
      isDeletedForAll: map['isDeletedForAll'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      replyId: map['replyId'] != null ? map['replyId'] as String : null,
      bookingId: map['bookingId'] != null ? map['bookingId'] as String : null,
      roommateId:
          map['roommateId'] != null ? map['roommateId'] as String : null,
      isSending: false,
      event: map['event'] != null
          ? Map<String, dynamic>.from((map['event'] as Map))
          : null,
      voice: map['voice'] != null
          ? Map<String, dynamic>.from((map['voice'] as Map))
          : null,
      files: List<ChatFile>.from(
        (map['files'] as List).map<ChatFile>(
          (x) => ChatFile.fromMap(x as Map<String, dynamic>),
        ),
      ),
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

  void updateFrom(ChatMessageV2 other) {
    id = other.id;
    senderId = other.senderId;
    recieverId = other.recieverId;
    type = other.type;
    content = other.content;
    recieveds = other.recieveds;
    reads = other.reads;
    deletes = other.deletes;
    isDeletedForAll = other.isDeletedForAll;
    createdAt = other.createdAt;
    replyId = other.replyId;
    bookingId = other.bookingId;
    roommateId = other.roommateId;
    event = other.event;
    voice = other.voice;
    files = other.files;
    isSending = other.isSending;
  }
}

class ChatFile {
  final String id;
  final String name;
  final String url;
  final int size;
  final String? thumbnail;
  ChatFile({
    required this.id,
    required this.name,
    required this.url,
    required this.size,
    this.thumbnail,
  });

  bool get haveThumbnail => thumbnail != null;

  bool get isImage => name.isImageFileName;

  bool get isVideo => name.isVideoFileName;

  bool get isPdf => name.isPDFFileName;

  String get typeLabel => extension(name).replaceFirst('.', '').toUpperCase();

  bool get isDocument {
    return DOCUMENT_EXTENSIONS.contains(extension(name.toLowerCase()));
  }

  bool get isFile {
    return OTHER_EXTENSIONS.contains(extension(name.toLowerCase()));
  }

  String get sizeText {
    const oneKB = 1024;
    if (size < oneKB) return "${size}B";
    if (size < oneKB * 1000) return "${size ~/ 1000}KB";
    if (size < oneKB * 1000000) return "${size ~/ 1000000}MB";
    if (size < oneKB * 1000000000) return "${size ~/ 1000000000}GB";
    return "${size / 1000000000000}TB";
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'url': url,
      'size': size,
      'thumbnail': thumbnail,
    };
  }

  factory ChatFile.fromMap(Map<String, dynamic> map) {
    return ChatFile(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      size: map['size'] as int,
      thumbnail: map['thumbnail'] != null ? map['thumbnail'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatFile.fromJson(String source) =>
      ChatFile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ChatFile other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.url == url &&
        other.size == size &&
        other.thumbnail == thumbnail;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
