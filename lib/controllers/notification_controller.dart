import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/message.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController {
  /// Use this method to detect when a new
  /// notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time
  /// that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps
  /// on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final payload = action.payload;
    if (action.buttonKeyPressed == "COPY_ID") {
      try {
        Clipboard.setData(ClipboardData(text: payload!['fpID'].toString()));
        showToast('ID ${"copied".tr}');
      } catch (_) {}
    }
  }

  // static Future<bool> get _canShowNotification async {
  //   try {
  //     final pref = await SharedPreferences.getInstance();
  //     if (pref.getBool("allowPushNotifications") == false) return false;
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  static Future<void> _saveNotification(String event, String message) async {
    try {
      final pref = await SharedPreferences.getInstance();

      final jsonUser = pref.getString("user");

      if (jsonUser == null) return;
      final user = User.fromJson(jsonUser);

      final key = "${user.id}notifications";

      final notifications = pref.getStringList(key) ?? [];

      final newNot = AppNotication.fromNow(message: message, event: event);

      if (!notifications.contains(newNot.toJson())) {
        notifications.insert(0, newNot.toJson());

        pref.setStringList(key, notifications);
      }
    } catch (_) {}
  }

  /// Request permission to send notification
  static Future<void> requestNotificationPermission(
    BuildContext? context,
  ) async {
    if (context == null) return;
    try {
      final canShowNotification =
          await AwesomeNotifications().isNotificationAllowed();
      if (!canShowNotification) {
        {
          // ignore: use_build_context_synchronously
          final shouldRequestPermission = await showCupertinoDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: Text("roomFinder".tr),
                  content: Text("requestNotificationPermissionMessage".tr),
                  actions: [
                    CupertinoDialogAction(
                      child: Text("no".tr),
                      onPressed: () => Get.back(result: false),
                    ),
                    CupertinoDialogAction(
                      child: Text("yes".tr),
                      onPressed: () => Get.back(result: true),
                    ),
                  ],
                );
              });
          if (shouldRequestPermission == true) {
            AwesomeNotifications().requestPermissionToSendNotifications();
          }
        }
      }
    } catch (_) {}
  }

  /// Handler for chance played

  static Future<void> firebaseMessagingHandler(RemoteMessage msg) async {
    switch (msg.data["event"].toString()) {
      case "new-booking":
      case "auto-reply":
      case "booking-offered":
      case "booking-declined":
      case "booking-cancelled":
        final message = msg.data["message"] ?? "new notification";

        if (msg.data["event"] != null) {
          _saveNotification(msg.data["event"], message);
        }

        AwesomeNotifications().createNotification(
          content: _createContent(
            title: "Booking".tr,
            body: message,
          ),
        );
        break;
      case "deal-ended":
      case "deal-paid":
        final message = msg.data["event"].toString();
        if (msg.data["event"] != null) {
          _saveNotification(msg.data["message"], message);
        }

        AwesomeNotifications().createNotification(
          content: _createContent(
            title: "Contracts/Deals".tr,
            body: message,
          ),
        );
        break;

      case 'new-message':
        try {
          final message = Message.fromJson(msg.data["jsonMessage"]);

          final pref = await SharedPreferences.getInstance();
          final jsonUser = pref.getString("user");

          var user = AppNotication.currentUser ?? User.fromJson(jsonUser!);

          final conv = (await ChatConversation.getSavedChat(
                  ChatConversation.createConvsertionKey(
                      user.id, message.sender.id))) ??
              ChatConversation.newConversation(friend: message.sender);

          conv.newMessageFromContent(message.content, false);
          conv.saveChat();
          ChatConversation.addUserConversationKeyToStorage(conv.key);

          AwesomeNotifications().createNotification(
            content: _createContent(
              title: message.sender.fullName,
              body: message.content,
            ),
          );
        } catch (_) {}

        break;
      default:
        break;
    }
  }
}

NotificationContent _createContent({
  String? title,
  String? body,
  Map<String, String?>? payload,
}) {
  return NotificationContent(
    id: Random().nextInt(1000),
    channelKey: "notification_channel",
    groupKey: "notification_channel_group",
    title: title,
    body: body,
    payload: payload,
    notificationLayout: NotificationLayout.Default,
  );
}

// NotificationContent _createMessageContent({
//   String? title,
//   String? body,
//   Map<String, String?>? payload,
// }) {
//   return NotificationContent(
//     id: Random().nextInt(1000),
//     channelKey: "message_notification_channel",
//     groupKey: "notification_message_group",
//     title: title,
//     body: body,
//     payload: payload,
//     notificationLayout: NotificationLayout.Messaging,
//   );
// }
