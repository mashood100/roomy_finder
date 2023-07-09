// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roomy_finder/models/chat_conversation_v2.dart';

const MESSAGE_DIR = "messages";

@pragma("vm:entry-point")
class ChatFileSystem {
  @pragma("vm:entry-point")
  static Future<bool> saveConversation(
    String userId,
    ChatConversationV2 conv,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      final path = join(appDir.path, MESSAGE_DIR, userId, conv.key);

      final file = File(path);

      file.createSync(recursive: true);

      file.writeAsStringSync(conv.toJson());

      return true;
    } catch (e, trace) {
      _log(e);
      _log(trace);

      return false;
    }
  }

  @pragma("vm:entry-point")
  static Future<ChatConversationV2?> getConversation(
    String userId,
    String key,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      final path = join(appDir.path, MESSAGE_DIR, userId, key);

      final file = File(path);

      if (!file.existsSync()) return null;

      final data = file.readAsStringSync();

      return ChatConversationV2.fromJson(data);
    } catch (e, trace) {
      _log(e);
      _log(trace);

      return null;
    }
  }

  @pragma("vm:entry-point")
  static Future<List<ChatConversationV2>> getSavedConversations(
      String userId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      final path = join(appDir.path, MESSAGE_DIR, userId);

      final dir = Directory(path);

      final chatsStrings = dir.listSync();

      final chats = chatsStrings
          .map((e) {
            try {
              final data = File(e.path).readAsStringSync();

              return ChatConversationV2.fromJson(data);
            } catch (e, trace) {
              _log(e);
              _log(trace);
              return null;
            }
          })
          .whereType<ChatConversationV2>()
          .toList();

      return chats;
    } catch (e, trace) {
      _log(e);
      _log(trace);

      return [];
    }
  }
}

void _log(data) => Get.log("CHAT_FILE_SYSTEM :: $data");
