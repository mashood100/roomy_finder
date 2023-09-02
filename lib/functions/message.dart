import 'dart:async';

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/models/chat/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/models/user/user.dart';
import 'package:roomy_finder/utilities/isar.dart';

@pragma("vm:entry-point")
Future<void> syncChatMessages() async {
  try {
    final lastM = ISAR.txnSync(() =>
        ISAR.chatMessageV2s.where().sortByCreatedAtDesc().findFirstSync());

    final lastMessageSyncDate = lastM?.createdAt.toIso8601String();

    final res = await ApiService.getDio.get(
      "/messaging-v2/sync-messages",
      data: {"lastMessageSyncDate": lastMessageSyncDate},
    );

    if (res.statusCode == 200) {
      final messages = (res.data["messages"] as List)
          .map((e) {
            try {
              return ChatMessageV2.fromMap(e);
            } catch (e) {
              return null;
            }
          })
          .whereType<ChatMessageV2>()
          .toList();

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putAllSync(messages));

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putAllSync(messages));

      ChatConversationV2.messagesAreSync = true;

      Get.log("Messages : ${messages.length}");

      final conversations = (res.data["conversations"] as List)
          .map((e) {
            try {
              return ChatConversationV2.fromMap(e);
            } catch (e) {
              return null;
            }
          })
          .whereType<ChatConversationV2>()
          .toList();

      Get.log("Conversations : ${conversations.length}");

      for (var c in conversations) {
        c.unReadMessageCount = messages.where((e) => e.key == c.key).length;
      }

      ISAR.writeTxnSync(() {
        ISAR.chatConversationV2s.putAllSync(conversations);
      });

      final users = conversations
          .expand((item) => [item.first.value, item.second.value])
          .whereType<User>()
          .toSet()
          .toList();

      Get.log("Users : ${users.length}");

      ISAR.writeTxnSync(() => ISAR.users.putAllSync(users));

      _syncStreamController.add(messages.map((e) => e.key).toSet().toList());
    }
  } catch (e, trace) {
    Get.log("$e");
    Get.log("$trace");
  }
}

// Emit the differnt keys of the messages sync
final _syncStreamController = StreamController<List<String>>.broadcast();

Stream<List<String>> get messageSyncStream => _syncStreamController.stream;
