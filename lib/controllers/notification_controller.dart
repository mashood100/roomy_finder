import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/booking/view_property_booking.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class NotificationController {
  static ReceivedAction? initialAction;

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
    if (action.actionType == ActionType.Default) {
      final payload = action.payload;
      if (payload == null) return;

      switch (payload["event"]) {
        case "new-booking":
        case "booking-offered":
        case "pay-property-rent-fee-completed-client":
        case "pay-property-rent-fee-completed-landlord":
          _handleBookingTappedEvents(payload);
          break;
        case "new-message":
          _handleChatMessageTappedEvents(payload);
          break;
        default:
      }
    }
    final payload = action.payload;
    if (payload == null) return;
    try {
      switch (payload["event"]) {
        case "new-booking":
        case "booking-offered":
          final res =
              await Dio().get("$API_URL/bookings/${payload["bookingId"]}");
          if (res.statusCode == 200) {
            final booking = PropertyBooking.fromMap(res.data);
            Get.to(() => ViewPropertyBookingScreen(booking: booking));
          }
          break;
        default:
      }
    } catch (e, trace) {
      Get.log("NOTIFICATION : $e");
      Get.log("NOTIFICATION : $trace");
    }
  }

  static Future<void> initializeLocalNotifications() async {
    // Awesome notifications initialized
    AwesomeNotifications().initialize(
      // null,
      'resource://drawable/launcher_icon',
      [
        NotificationChannel(
          channelGroupKey: 'notification_channel_group',
          channelKey: 'notification_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Room Finder default notification channel',
          defaultColor: Colors.purple,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          ledColor: Colors.purple,
        ),
        NotificationChannel(
          channelGroupKey: 'chat_channel_group_key',
          channelKey: 'chat_channel_key',
          channelName: 'Chat nottifications channel',
          channelDescription:
              'Room Finder chat notifications notification channel',
          defaultColor: Colors.purple,
          channelShowBadge: true,
          ledColor: Colors.purple,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'notification_channel_group',
          channelGroupName: 'Notification Group',
        ),
        NotificationChannelGroup(
          channelGroupKey: 'chat_channel_group_key',
          channelGroupName: 'Chat group notification',
        ),
      ],
      debug: true,
    );
    AwesomeNotifications().resetGlobalBadge();

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
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
  ///

  static Future<void> firebaseMessagingHandler(
      RemoteMessage msg, bool isForeground) async {
    switch (msg.data["event"].toString()) {
      case "new-booking":
      case "booking-offered":
        final message = msg.data["message"] ?? "new notification";
        final bookingId = "${msg.data["bookingId"]}";

        if (msg.data["event"] != null) {
          _saveNotification(msg.data["event"], message);
        }
        if (isForeground) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: Random().nextInt(1000),
              channelKey: "notification_channel",
              groupKey: "notification_channel_group",
              title: "Booking",
              body: message,
              notificationLayout: NotificationLayout.BigText,
              payload: {
                "bookingId": bookingId,
                "event": msg.data["event"].toString(),
              },
            ),
          );
        }

        break;
      case "auto-reply":
      case "booking-declined":
      case "booking-cancelled":
      case "pay-property-rent-fee-completed-client":
      case "pay-property-rent-fee-completed-landlord":
        final message = msg.data["message"] ?? "new notification";

        if (msg.data["event"] != null) {
          _saveNotification(msg.data["event"], message);
        }

        if (isForeground) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: Random().nextInt(1000),
              channelKey: "notification_channel",
              groupKey: "notification_channel_group",
              title: "Booking",
              body: message,
              notificationLayout: NotificationLayout.BigText,
            ),
          );
        }

        break;
      case "new-message":
        _messageNotificationHandler(msg);
        break;
      case "plan-upgraded-successfully":
        final message = msg.data["message"] ?? "new notification";

        if (msg.data["event"] != null) {
          _saveNotification(msg.data["event"], message);
        }

        if (isForeground) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: Random().nextInt(1000),
              channelKey: "notification_channel",
              groupKey: "notification_channel_group",
              title: "Premium",
              body: message,
              notificationLayout: NotificationLayout.BigText,
            ),
          );
        }
        break;

      default:
        break;
    }
  }

  static Future<void> _messageNotificationHandler(RemoteMessage msg) async {
    try {
      final message = types.Message.fromJson(jsonDecode(msg.data["message"]));
      final sender = User.fromJson(msg.data["sender"]);
      final reciever = User.fromJson(msg.data["reciever"]);

      final convKey =
          ChatConversation.createConvsertionKey(reciever.id, sender.id);

      final conv = await ChatConversation.getSavedChat(convKey) ??
          ChatConversation.newConversation(friend: sender);

      conv.newMessage(message);
      conv.saveChat();
      ChatConversation.addUserConversationKeyToStorage(conv.key);

      final String notificationMessage;

      if (message is types.TextMessage) {
        notificationMessage = message.text;
      } else if (message is types.ImageMessage) {
        notificationMessage = "Sent an image";
      } else if (message is types.AudioMessage) {
        notificationMessage = "Sent a voice message";
      } else {
        notificationMessage = "Sent a file";
      }

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: Random().nextInt(1000),
          channelKey: "chat_channel_key",
          groupKey: "chat_channel_group_key",
          title: sender.firstName,
          body: notificationMessage,
          notificationLayout: NotificationLayout.Messaging,
          payload: Map<String, String?>.from(msg.data),
        ),
      );
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

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

  static Future<void> onFCMMessageOpenedAppHandler(
      RemoteMessage message) async {
    switch (message.data["event"]) {
      case "new-booking":
      case "booking-offered":
      case "pay-property-rent-fee-completed-client":
      case "pay-property-rent-fee-completed-landlord":
        _handleBookingTappedEvents(message.data);
        break;
      case "new-message":
        _handleChatMessageTappedEvents(message.data);
        break;
      default:
    }
  }

  static Future<void> _handleBookingTappedEvents(
      Map<String, dynamic> data) async {
    try {
      final res = await ApiService.getDio.get(
        "/bookings/property-ad/${data["bookingId"]}",
      );

      if (res.statusCode == 200) {
        final booking = PropertyBooking.fromMap(res.data);

        Get.to(() => ViewPropertyBookingScreen(booking: booking));
      }
    } catch (e) {
      Get.log("$e");
    }
  }

  static Future<void> _handleChatMessageTappedEvents(
      Map<String, dynamic> data) async {
    try {
      final sender = User.fromJson(data["sender"]);
      final reciever = User.fromJson(data["reciever"]);

      final convKey =
          ChatConversation.createConvsertionKey(reciever.id, sender.id);

      final conv = await ChatConversation.getSavedChat(convKey) ??
          ChatConversation.newConversation(friend: sender);
      Get.to(() => FlyerChatScreen(conversation: conv));
    } catch (e) {
      Get.log("$e");
    }
  }
}
