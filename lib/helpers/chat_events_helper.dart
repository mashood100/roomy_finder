import 'dart:async';

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/chat/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/models/user/user.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/utilities/isar.dart';

typedef ChatEventStreamData = (
  ChatEvents event,
  String key,
  ChatMessageV2? message,
);

class ChatEventHelper {
  @pragma("vm:entry-point")
  static final _streamController =
      StreamController<ChatEventStreamData>.broadcast();

  @pragma("vm:entry-point")
  static Stream<ChatEventStreamData> get stream => _streamController.stream;

  @pragma("vm:entry-point")
  static void messageDeletedHandler(data) {
    final messageId = data["messageId"];
    final userId = data["userId"];

    ISAR.writeTxnSync(() {
      final msg = ISAR.chatMessageV2s.getSync(fastHash(messageId));

      if (msg != null) {
        msg.deletes = List.from(msg.deletes)..add(userId);

        ISAR.chatMessageV2s.putSync(msg);
      }
    });
  }

  @pragma("vm:entry-point")
  static Future<void> userUnblockedHandler(data) async {
    final key = data["key"];
    final userId = data["userId"];

    var conv = ISAR.txnSync(() {
      return ISAR.chatConversationV2s.getSync(fastHash(key));
    });

    if (conv == null || conv.first.value == null || conv.second.value == null) {
      conv = await ApiService.fetchConversation(key);
    }

    if (conv == null) return;

    conv.blocks = List.from(conv.blocks)..removeWhere((e) => e == userId);

    ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conv!));

    _streamController.add((ChatEvents.userUnBlocked, key, null));
  }

  @pragma("vm:entry-point")
  static Future<void> userBlockedHandler(data) async {
    final key = data["key"];
    final userId = data["userId"];

    var conv = ISAR.txnSync(() {
      return ISAR.chatConversationV2s.getSync(fastHash(key));
    });

    if (conv == null || conv.first.value == null || conv.second.value == null) {
      conv = await ApiService.fetchConversation(key);
    }

    if (conv == null) return;

    if (conv.blocks.contains(userId)) return;

    conv.blocks = List.from(conv.blocks)..add(userId);

    ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conv!));

    _streamController.add((ChatEvents.userBlocked, key, null));
  }

  @pragma("vm:entry-point")
  static Future<void> messageReadHandler(data) async {
    final messageId = data["messageId"];
    final userId = data["userId"];
    final key = data["key"];

    try {
      var msg =
          ISAR.txnSync(() => ISAR.chatMessageV2s.getSync(fastHash(messageId)));

      msg ??= await ApiService.fetchMessage(messageId);

      if (msg == null) return;

      if (!msg.reads.contains(userId)) {
        msg.reads = List.from(msg.reads)..add(userId.toString());
      }

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(msg!));

      _streamController.add((ChatEvents.messageRecieved, key, null));

      _streamController.add((ChatEvents.messageRead, key, null));
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  @pragma("vm:entry-point")
  static Future<void> messageRecievedHandler(data) async {
    final messageId = data["messageId"];
    final userId = data["userId"];
    final key = data["key"];

    try {
      var msg =
          ISAR.txnSync(() => ISAR.chatMessageV2s.getSync(fastHash(messageId)));

      msg ??= await ApiService.fetchMessage(messageId);

      if (msg == null) return;

      if (!msg.recieveds.contains(userId)) {
        msg.recieveds = List.from(msg.recieveds)..add(userId.toString());
      }

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(msg!));

      _streamController.add((ChatEvents.messageRecieved, key, null));
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  @pragma("vm:entry-point")
  static Future<void> handleMarkAsReadReplySuceeded(data) async {
    try {
      final key = data["key"];

      var conv = ISAR.txnSync(() {
        return ISAR.chatConversationV2s.getSync(fastHash(key));
      });

      if (conv == null ||
          conv.first.value == null ||
          conv.second.value == null) {
        conv = await ApiService.fetchConversation(key);
      }

      if (conv == null) return;

      conv.unReadMessageCount = 0;

      ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conv!));

      _streamController.add((ChatEvents.markAsReadReplySuceeded, key, null));
    } on IsarError catch (e) {
      Get.log(e.message);
    }
  }

  // When message is replied from notification tray,
  // The server will new an event with a new message
  @pragma("vm:entry-point")
  static Future<void> replyMessageFromTraySuceeded(data) async {
    try {
      final key = data["key"];

      final msg = ChatMessageV2.fromMap(data["message"]);

      var conv = ISAR.txnSync(() {
        return ISAR.chatConversationV2s.getSync(fastHash(key));
      });

      if (conv == null ||
          conv.first.value == null ||
          conv.second.value == null) {
        conv = await ApiService.fetchConversation(key);
      }

      if (conv == null) return;

      conv.lastMessage.value = msg;
      conv.unReadMessageCount = 0;

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(msg));

      ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conv!));

      ISAR.writeTxnSync(() => ISAR.users.putSync(conv!.first.value!));
      ISAR.writeTxnSync(() => ISAR.users.putSync(conv!.second.value!));

      _streamController.add(
        (ChatEvents.replyMessageFromRaySuccedded, key, msg),
      );
    } on IsarError catch (e) {
      Get.log(e.message);
    }
  }

  @pragma("vm:entry-point")
  static void newMessageHandler(data) async {
    try {
      final msg = ChatMessageV2.fromMap(data["message"]);

      var conv = ISAR
          .txnSync(() => ISAR.chatConversationV2s.getSync(fastHash(msg.key)));

      conv ??= ChatConversationV2(
        key: msg.key,
        blocks: [],
        createdAt: DateTime.now(),
      );

      if (conv.first.value == null) {
        var sender = await ApiService.fetchUser(msg.senderId);

        conv.first.value = sender ?? User.GUEST_USER;
      }

      if (conv.second.value == null) {
        var receiver = await ApiService.fetchUser(msg.recieverId);

        conv.second.value = receiver ?? User.GUEST_USER;
      }

      conv.lastMessage.value = msg;
      conv.unReadMessageCount += 1;

      ISAR.writeTxnSync(() => ISAR.users.putSync(conv!.first.value!));
      ISAR.writeTxnSync(() => ISAR.users.putSync(conv!.second.value!));

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(msg));

      ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conv!));

      _streamController.add((ChatEvents.newMessage, msg.key, msg));

      var title = data["notificationTitle"]?.toString();
      var category = AppNotificationCategory.messaging;

      var shouldShow = true;

      if (ChatConversationV2.currentChatRoomKey == null) shouldShow = true;

      if (Home.chatIsCurrentTab) shouldShow = false;

      if (ChatConversationV2.currentChatRoomKey == conv.key) {
        shouldShow = false;
      }

      if (data["isBackgroundFCM"] == true) {
        shouldShow = false;
      }

      ChatConversationV2.messagesNotificationIds.add(msg.localNotificationsId);

      if (shouldShow) {
        await NotificationController.showNotification(
          title ?? conv.other.fullName,
          msg.content ?? msg.typedMessage,
          payload: msg.createLocalNotificationPayload(data["key"]),
          category: category,
          id: msg.localNotificationsId,
        );
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }
}

enum ChatEvents {
  newMessage,
  messageRead,
  messageDeleted,
  replyMessageFromRaySuccedded,
  markAsReadReplySuceeded,
  messageRecieved,
  userBlocked,
  userUnBlocked,
}
