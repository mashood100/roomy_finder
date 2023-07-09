// ignore_for_file: library_prefixes

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:roomy_finder/classes/chat_file_system.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/maintenance/screens/view_maintenance/details.dart';
import 'package:roomy_finder/models/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/booking/view_property_booking.dart';

final _random = Random();

class LocalNotificationController {
  static final plugin = FlutterLocalNotificationsPlugin();

  static Future<bool?> requestNotificationPermission() async {
    return await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  static Future<void> initializeLocalNotifications() async {
    await plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }

  static void onDidReceiveNotificationResponse(NotificationResponse details) {
    final data = json.decode(details.payload!) as Map<String, dynamic>;

    if (details.actionId != null) {
      switch (details.actionId) {
        case "messaging_reply_action":
          if (details.input != null) {
            _handleChatMessageV2TappedEvents(
                data, "reply", true, details.input);
          }
          break;
        case "messaging_mark_as_read_action":
          _handleChatMessageV2TappedEvents(data, "mark-as-read", true);
          break;
        case "booking_survey_landlord_yes_action":
          _handleBookingSurveyActionsTapped(data, "landlord", action: "yes");
          break;
        case "booking_survey_landlord_no_action":
          _handleBookingSurveyActionsTapped(data, "landlord", action: "no");
          break;
        case "booking_survey_tenant_not_clean_action":
          _handleBookingSurveyActionsTapped(data, "tenant", action: "notClean");
          break;
        case "booking_survey_tenant_picture_donot_match_action":
          _handleBookingSurveyActionsTapped(data, "tenant",
              action: "pictureDoNotMatch");
          break;
        case "booking_survey_tenant_i_did_not_come_action":
          _handleBookingSurveyActionsTapped(data, "tenant",
              action: "IDidNotCome");
          break;
        default:
      }
    } else {
      defaultNotificationTapHandler(data, true);
    }
  }

  @pragma("vm:entry-point")
  static void onDidReceiveBackgroundNotificationResponse(
      NotificationResponse details) {
    final data = json.decode(details.payload!) as Map<String, dynamic>;

    if (details.actionId != null) {
      switch (details.actionId) {
        case "messaging_reply_action":
          if (details.input != null) {
            _handleChatMessageV2TappedEvents(
              data,
              "reply",
              false,
              details.input,
            );
          }
          break;
        case "messaging_mark_as_read_action":
          _handleChatMessageV2TappedEvents(data, "mark-as-read", false);
          break;
        case "booking_survey_landlord_yes_action":
          _handleBookingSurveyActionsTapped(data, "landlord", action: "yes");
          break;
        case "booking_survey_landlord_no_action":
          _handleBookingSurveyActionsTapped(data, "landlord", action: "no");
          break;
        case "booking_survey_tenant_not_clean_action":
          _handleBookingSurveyActionsTapped(data, "tenant", action: "notClean");
          break;
        case "booking_survey_tenant_picture_donot_match_action":
          _handleBookingSurveyActionsTapped(data, "tenant",
              action: "pictureDoNotMatch");
          break;
        case "booking_survey_tenant_i_did_not_come_action":
          _handleBookingSurveyActionsTapped(data, "tenant",
              action: "IDidNotCome");
          break;
        default:
      }
    } else {
      defaultNotificationTapHandler(data, false);
    }
  }

  // Show notification
  static Future<int> showNotification(
    String? title,
    String? body, {
    required Map<String, dynamic> payload,
    AppNotificationCategory? category,
    int badgeNumber = 0,
    String? groupKey,
  }) async {
    final List<AndroidNotificationAction> actions = [];
    // var launInfo = await    _plugin.getNotificationAppLaunchDetails();

    String darwinCategoryId;

    switch (category) {
      case AppNotificationCategory.messaging:
        actions.addAll(
          const [
            AndroidNotificationAction(
              "messaging_reply_action",
              "Reply",
              inputs: [AndroidNotificationActionInput()],
            ),
            AndroidNotificationAction(
              "messaging_mark_as_read_action",
              "Mark as read",
            ),
          ],
        );

        darwinCategoryId = "messaging";

        break;
      case AppNotificationCategory.bookingSurveyLandlord:
        actions.addAll(
          const [
            AndroidNotificationAction(
              "booking_survey_landlord_yes_action",
              "Yes",
            ),
            AndroidNotificationAction(
              "booking_survey_landlord_no_action",
              "No",
            ),
          ],
        );

        darwinCategoryId = "booking_survey_landlord";

        break;
      case AppNotificationCategory.bookingSurveyTenant:
        actions.addAll(
          const [
            AndroidNotificationAction(
              "booking_survey_tenant_not_clean_action",
              "Property no clean",
            ),
            AndroidNotificationAction(
              "booking_survey_tenant_picture_donot_match_action",
              "Picture don't match",
            ),
            AndroidNotificationAction(
              "booking_survey_tenant_i_did_not_come_action",
              "I didn't come",
            ),
          ],
        );

        darwinCategoryId = "booking_survey_tenant";

        break;
      default:
        darwinCategoryId = "default";
    }

    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default channel',
      channelDescription: 'Default Roomy Finder notification channnel',
      importance: Importance.defaultImportance,
      priority: Priority.high,
      groupKey: groupKey,
      actions: actions,
    );

    final darwinDetail = DarwinNotificationDetails(
      badgeNumber: badgeNumber,
      categoryIdentifier: darwinCategoryId,
      presentBadge: badgeNumber == 0 ? false : true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetail,
    );
    var id = _random.nextInt(1000);
    await plugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: json.encode(payload),
    );

    return id;
  }

  @pragma("vm:entry-point")
  static Future<void> firebaseMessagingHandler(
      RemoteMessage msg, bool isForeground) async {
    final notification = msg.notification;

    final data = msg.data;
    final event = data["event"];

    AppNotificationCategory? category;

    switch (event) {
      case "new-message-v2":
        category = AppNotificationCategory.messaging;
        break;
      case "pay-cash-survey-landlord":
        category = AppNotificationCategory.bookingSurveyLandlord;
        break;
      case "pay-cash-survey-tenant":
        category = AppNotificationCategory.bookingSurveyTenant;
        break;
      default:
    }

    var shouldSaveNotification = ![
      "new-message-v2",
      "pay-cash-survey-landlord",
      "pay-cash-survey-tenant",
      "message-reply-succeded"
    ].contains(event);

    if (shouldSaveNotification) {
      _saveNotification(
        data["event"] ?? "Roomy Finder",
        notification?.body ?? data["message"],
        notification?.title ?? data["title"] ?? data["notificationTitle"],
      );
    }

    if (isForeground) {
      if (notification != null) {
        await showNotification(
          notification.title,
          notification.body,
          payload: msg.data,
          category: category,
        );

        switch (event) {
          case "new-booking":
            ApiService.setUnreadBookingCount();

            break;
          default:
        }
      }
    } else {
      var title = data["notificationTitle"].toString();
      switch (event) {
        case "pay-cash-survey-landlord":
          final survey = jsonDecode(data["payload"]);
          category = AppNotificationCategory.bookingSurveyLandlord;

          showNotification(
            "Booking Survey",
            survey["message"],
            payload: msg.data,
            category: category,
          );
          break;
        case "pay-cash-survey-tenant":
          final survey = jsonDecode(data["payload"]);
          category = AppNotificationCategory.bookingSurveyTenant;
          showNotification(
            "Booking Survey",
            survey["message"],
            payload: msg.data,
            category: category,
          );
          break;
        case "new-message-v2":
          category = AppNotificationCategory.messaging;
          final msg = ChatMessageV2.fromJson(data["message"]);

          final id = await showNotification(
            title,
            msg.content ?? msg.typedMessage,
            payload: msg.createLocalNotificationPayload(data["key"]),
            category: category,
          );

          final key =
              ChatConversationV2.createKey(msg.recieverId, msg.senderId);

          var conv = await ChatFileSystem.getConversation(msg.recieverId, key);

          if (conv == null) {
            final sender = User(
              id: msg.senderId,
              type: "landlord",
              email: "guest@email.com",
              firstName: title,
              lastName: "",
              isPremium: false,
              createdAt: DateTime.now(),
            );

            final reciever = User(
              id: msg.recieverId,
              type: "landlord",
              email: "guest@email.com",
              firstName: "Guest",
              lastName: "",
              isPremium: false,
              createdAt: DateTime.now(),
            );

            conv = ChatConversationV2(
              key: key,
              first: sender,
              second: reciever,
              messages: [msg],
              blocks: [],
            );
          }
          conv.localNotificationsIds.add(id);
          await conv.saveToStorage(msg.recieverId);

          break;
        default:
      }
    }
  }

  static Future<void> _saveNotification(
    String event,
    String message,
    String? title,
  ) async {
    try {
      final pref = await SharedPreferences.getInstance();

      final jsonUser = pref.getString("user");

      if (jsonUser == null) return;
      final user = User.fromJson(jsonUser);

      final appDir = await getApplicationSupportDirectory();

      var filePath = path.join(appDir.path, "${user.id}-notifications.json");

      final notifications = await getSaveNotifications(user.id);

      final newNot = AppNotification.fromNow(
        message: message,
        title: title,
        event: event,
        isRead: false,
      );

      if (!notifications.contains(newNot)) {
        notifications.insert(0, newNot);

        final file = File(filePath);
        file.writeAsStringSync(json.encode(notifications));
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  static Future<bool> deleteNotification(
    String userId,
    AppNotification notication,
  ) async {
    try {
      final appDir = await getApplicationSupportDirectory();

      var filePath = path.join(appDir.path, "$userId-notifications.json");

      final notifications = await getSaveNotifications(userId);

      notifications.remove(notication);

      final file = File(filePath);
      file.writeAsStringSync(json.encode(notifications));

      return true;
    } catch (e, trace) {
      log(e);
      log(trace);
      return false;
    }
  }

  static Future<List<AppNotification>> getSaveNotifications(
      String userId) async {
    try {
      final appDir = await getApplicationSupportDirectory();

      var filePath = path.join(appDir.path, "$userId-notifications.json");

      final file = File(filePath);

      if (!file.existsSync()) return [];

      final content = file.readAsStringSync();

      final data = json.decode(content);

      final notifications = (data as List)
          .map((e) {
            try {
              return AppNotification.fromJson(e);
            } catch (e, trace) {
              log(e);
              log(trace);
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();

      return notifications;
    } catch (e, trace) {
      log(e);
      log(trace);
      return [];
    }
  }

  static Future<void> _handleBookingTappedEvents(Map data) async {
    try {
      final booking = await ApiService.fetchBooking(data["bookingId"]);
      if (booking != null) {
        Get.to(() => ViewPropertyBookingScreen(booking: booking));
      }
    } catch (e) {
      Get.log("$e");
    }
  }

  static Future<void> _handleBookingSurveyActionsTapped(
    Map<String, dynamic> data,
    String account, {
    String? action,
  }) async {
    try {
      final survey = jsonDecode(data["payload"]);
      if (action == null) {
        final answers = List<Map<String, dynamic>>.from(survey["answers"]);
        final message = survey["message"];

        action = await showAnsweringDialog(
          message,
          title: "Booking Survey",
          answers: answers,
        );
      }

      if (action == null) return;

      final res = await Dio().post(
        "$API_URL/bookings/property-ad/pay-cash/survey-response/$account",
        data: {
          "bookingId": survey["bookingId"],
          "action": action,
        },
      );
      if (res.statusCode == 200) {
        showToast("Answer sent successfully");
      } else {
        Get.log("${res.statusCode}");
        showToast("Something went wrong. Please try again");
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  static void handleFCMMessageOpenedAppMessage(RemoteMessage msg) {
    defaultNotificationTapHandler(msg.data, true);
  }

  static void handleInitialMessage(NotificationResponse not) {
    if (not.payload != null) {
      var data = jsonDecode(not.payload!) as Map<String, dynamic>;

      defaultNotificationTapHandler(data, true);
    }
  }

  static void defaultNotificationTapHandler(
      Map<String, dynamic> data, bool isForeground) {
    final event = data["event"];

    switch (event) {
      case "new-message-v2":
        _handleChatMessageV2TappedEvents(data, "message-tapped", isForeground);
        break;
      case "pay-cash-survey-landlord":
        _handleBookingSurveyActionsTapped(data, "landlord");
        break;
      case "pay-cash-survey-tenant":
        _handleBookingSurveyActionsTapped(data, "tenant");
        break;
      case "new-booking":
      case "booking-offered":
      case "pay-property-rent-fee-completed-client":
      case "pay-property-rent-fee-completed-landlord":
        _handleBookingTappedEvents(data);
        break;
      case "maintenance-request-new":
      case "maintenance-offer-new":
      case "maintenance-offer-accepted":
      case "maintenance-offer-declined":
      case "maintenance-offer-submit":
      case "maintenance-offer-submit-approved":
      case "maintenance-offer-submit-rejected":
      case "maintenance-paid-successfully":
        _handleMaintenanceTappedEvents(data);
        break;
      default:
    }
  }

  static Future<void> _handleMaintenanceTappedEvents(
      Map<String, dynamic> data) async {
    try {
      final res = await ApiService.getDio.get(
        "/maintenances/single-maintenance?id=${data["maintenanceId"]}",
      );

      if (res.statusCode == 200) {
        final maintenance = Maintenance.fromMap(res.data);

        Get.to(() => ViewMaintenanceDetailsScreen(maintenance: maintenance));
      }
    } catch (e) {
      Get.log("$e");
    }
  }

  static Future<void> _handleChatMessageV2TappedEvents(
    Map<String, dynamic> data,
    String action,
    bool isForeground, [
    String? anwser,
  ]) async {
    final key = data["key"] as String;
    final senderId = data["senderId"] as String;

    _log(isForeground);

    if (isForeground) {
      ChatConversationV2.onLocalNotificationsAction(data);

      User? user;
      try {
        final conv = ChatConversationV2.conversations
            .firstWhereOrNull((e) => e.key == key);

        if (conv != null) user = conv.other;
      } catch (_) {}

      user ??= await ApiService.fetchUser(senderId);

      if (user == null) {
        _log("Can't find other user in new message");
        return;
      }

      moveToChatRoom(AppController.me, user);
    } else {
      await ApiService.updateMessage({
        ...data,
        "action": action,
        "reply": anwser,
      });
    }
  }
}

const _androidSettings = AndroidInitializationSettings('launcher_icon');

final _darwinSettings = DarwinInitializationSettings(
  notificationCategories: [
    const DarwinNotificationCategory('default'),
    DarwinNotificationCategory(
      'messaging',
      actions: [
        DarwinNotificationAction.text(
          "messaging_reply_action",
          "Reply",
          buttonTitle: "Send",
          placeholder: "Type here",
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
        DarwinNotificationAction.plain(
          "messaging_mark_as_read_action",
          "Mark as read",
        ),
      ],
    ),
    DarwinNotificationCategory(
      'booking_survey_landlord',
      actions: [
        DarwinNotificationAction.plain(
          "booking_survey_landlord_yes_action",
          "Yes",
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
        DarwinNotificationAction.plain(
          "booking_survey_landlord_no_action",
          "No",
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
      ],
    ),
    DarwinNotificationCategory(
      'booking_survey_tenant',
      actions: [
        DarwinNotificationAction.plain(
          "booking_survey_tenant_not_clean_action",
          "Property not Clean",
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
        DarwinNotificationAction.plain(
          "booking_survey_tenant_picture_donot_match_action",
          "Picture don't match",
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
        DarwinNotificationAction.plain(
          "booking_survey_tenant_i_did_not_come_action",
          "I didn't come",
          options: {DarwinNotificationActionOption.authenticationRequired},
        ),
      ],
    ),
  ],
);

final initializationSettings = InitializationSettings(
  android: _androidSettings,
  iOS: _darwinSettings,
);

enum AppNotificationCategory {
  messaging,
  bookingSurveyLandlord,
  bookingSurveyTenant,
}

// void _log(data) => print("[ LOCAL_NOTIFICATION ] : $data");
void _log(data) {}
