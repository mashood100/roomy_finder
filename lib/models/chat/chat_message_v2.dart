// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';

import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/utilities/data.dart';

part 'chat_message_v2.g.dart';

@Collection()
class ChatMessageV2 {
  @Index(unique: true, replace: true)
  String id;

  Id get isarId => fastHash(id);

  @Index()
  String key;

  @Index()
  String senderId;

  @Index()
  String recieverId;
  String type;
  String? content;
  List<String> recieveds;
  List<String> reads;
  List<String> deletes;
  bool isDeletedForAll;

  @Index()
  DateTime createdAt;
  String? replyId;
  String? bookingId;
  String? roommateId;
  String? event;
  ChatVoiceNote? voice;
  List<ChatFile> files;
  bool isSending;

  int localNotificationsId;

  ChatMessageV2({
    required this.id,
    required this.senderId,
    required this.recieverId,
    required this.key,
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
    required this.localNotificationsId,
  });

  @ignore
  bool get isMine => senderId == AppController.me.id;

  @ignore
  bool get isRecieved => isRead || recieveds.contains(recieverId);

  @ignore
  bool get isRead => reads.contains(recieverId);

  @ignore
  bool get isDeleted =>
      deletes.contains(AppController.me.id) || isDeletedForAll;

  @ignore
  bool get isVoice => type == "voice";

  @ignore
  String get typedMessage {
    if (voiceFile != null) {
      var min = voiceMinutues.toString().padLeft(2, "0");
      var sec = voiceSeconds.toString().padLeft(2, "0");

      var text1 = voiceMinutues! > 0 ? "$min Min :" : "";

      return "Sent a voice Note ($text1 $sec Sec)";
    }
    return "Sent a $type";
  }

  @ignore
  Uint8List? get voiceFile {
    return voice == null ? null : Uint8List.fromList(voice!.bytes);
  }

  @ignore
  int? get voiceMinutues {
    if (voice != null && voice!.seconds != null) {
      var i = voice!.seconds!;
      return i ~/ 60;
    }
    return null;
  }

  @ignore
  int? get voiceSeconds => voice?.seconds;

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
      'key': key,
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
      'voice': voice?.toMap(),
      'files': files.map((x) => x.toMap()).toList(),
      "localNotificationsId": localNotificationsId,
    };
  }

  factory ChatMessageV2.fromMap(Map<String, dynamic> map) {
    if (map["deletes"] is! List) map["deletes"] = [];
    if (map["recieveds"] is! List) map["recieveds"] = [];
    if (map["reads"] is! List) map["reads"] = [];

    return ChatMessageV2(
      id: map['id'] as String,
      key: map['key'] as String,
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
      event: map['event']?.toString(),
      voice: map['voice'] != null
          ? ChatVoiceNote.fromMap((map['voice'] as Map<String, dynamic>))
          : null,
      files: List<ChatFile>.from(
        (map['files'] as List).map<ChatFile>(
          (x) => ChatFile.fromMap(x as Map<String, dynamic>),
        ),
      ),
      localNotificationsId:
          int.tryParse(map["localNotificationsId"].toString()) ??
              Random().nextInt(pow(2, 30).toInt()),
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

  @ignore
  @override
  int get hashCode {
    return id.hashCode;
  }

  void updateFrom(ChatMessageV2 other) {
    id = other.id;
    key = other.key;
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

@Embedded()
class ChatFile {
  late String id;
  late String name;
  late String url;
  late int size;
  late String? thumbnail;

  ChatFile();

  @ignore
  bool get haveThumbnail => thumbnail != null;

  @ignore
  bool get isImage => name.isImageFileName;

  @ignore
  bool get isVideo => name.isVideoFileName;

  @ignore
  bool get isPdf => name.isPDFFileName;

  @ignore
  String get typeLabel => extension(name).replaceFirst('.', '').toUpperCase();

  @ignore
  bool get isDocument {
    return DOCUMENT_EXTENSIONS.contains(extension(name.toLowerCase()));
  }

  @ignore
  bool get isFile {
    return OTHER_EXTENSIONS.contains(extension(name.toLowerCase()));
  }

  @ignore
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
    var chatFile = ChatFile();
    chatFile.id = map['id'] as String;
    chatFile.name = map['name'] as String;
    chatFile.url = map['url'] as String;
    chatFile.size = map['size'] as int;
    chatFile.thumbnail =
        map['thumbnail'] != null ? map['thumbnail'] as String : null;
    return chatFile;
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

  @ignore
  @override
  int get hashCode {
    return id.hashCode;
  }
}

@Embedded()
class ChatVoiceNote {
  String? name;
  late List<int> bytes;
  int? seconds;

  ChatVoiceNote({
    this.name,
    this.seconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bytes': {"type": "Buffer", "data": bytes},
      'seconds': seconds,
    };
  }

  factory ChatVoiceNote.fromMap(Map<String, dynamic> map) {
    var v = ChatVoiceNote(
      name: map['name'],
      seconds: map['seconds'],
    );

    final buff = map['bytes'] as Map<String, dynamic>;

    v.bytes = List<int>.from((buff['data'] as List));
    return v;
  }

  String toJson() => json.encode(toMap());

  factory ChatVoiceNote.fromJson(String source) =>
      ChatVoiceNote.fromMap(json.decode(source));
}
