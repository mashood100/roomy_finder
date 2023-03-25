library home_screen;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/check_for_update.dart';
import 'package:roomy_finder/functions/dynamic_link_handler.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/home/account_tab.dart';
import 'package:roomy_finder/screens/home/favorites_tab.dart';
import 'package:roomy_finder/screens/home/home_tab.dart';
import 'package:roomy_finder/screens/home/chat_tab.dart';
import 'package:roomy_finder/screens/utility_screens/update_app.dart';

class HomeController extends LoadingController {
  final currentTabIndex = 0.obs;
  Timer? _popTimer;
  int _popClickCounts = 0;

  @override
  void onInit() {
    if (AppController.initialLink != null) {
      dynamicLinkHandler(AppController.initialLink!);
    }

    Future(_runStartFutures);
    Future(_handleInitialMessage);

    if (NotificationController.initialAction != null) {
      NotificationController.onActionReceivedMethod(
        NotificationController.initialAction!,
      );
      NotificationController.initialAction = null;
    }

    super.onInit();

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;
      // AppController.instance.haveNewMessage(false);
      switch (data["event"]) {
        case "plan-upgraded-successfully":
          AppController.instance.user.update((val) {
            if (val != null) {
              val.isPremium = true;
            }
          });
          showToast("Plan successfully upgraded to premium");

          break;
        case "new-message":
          if (currentTabIndex.value != 2) {
            AppController.instance.haveNewMessage(true);
          }

          break;
        default:
      }
    });
  }

  // Initial Remote message handler
  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      NotificationController.onFCMMessageOpenedAppHandler(message);
    }
    await NotificationController.requestNotificationPermission(Get.context);
  }

  Future<void> _runStartFutures() async {
    await _promptUpdate();
    await NotificationController.requestNotificationPermission(Get.context);
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<bool> _onWillPop() async {
    if (_popClickCounts > 0) return true;

    _popClickCounts++;
    showToast("clickAgainToQuitApp".tr);
    _popTimer = Timer(const Duration(seconds: 2), () {
      _popClickCounts = 0;
    });
    return false;
  }

  Future<void> _promptUpdate() async {
    final context = Get.context;
    if (context == null) return;

    final updateIsAvailable = await checkForAppUpdate();

    if (updateIsAvailable) {
      Get.offAll(() => const UpdateAppScreen());
    }
  }

  @override
  void onClose() {
    if (_popTimer != null) _popTimer!.cancel();
    super.onClose();
  }
}

class Home extends GetView<HomeController> {
  const Home({super.key});

  static const tabs = <HomeScreenSupportable>[
    HomeTab(),
    AccountTab(),
    MessagesTab(),
    FavoriteTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return WillPopScope(
      onWillPop: controller._onWillPop,
      child: Obx(() {
        return Scaffold(
          appBar: tabs[controller.currentTabIndex.value].appBar,
          drawer: const Drawer(),
          body: LazyLoadIndexedStack(
            index: controller.currentTabIndex.value,
            children: tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentTabIndex.value,
            onTap: (index) {
              controller.currentTabIndex(index);
              if (index == 2) {
                final chatController = Get.put(ChatTabController());
                chatController.update();
                AppController.instance.haveNewMessage(false);
                AwesomeNotifications()
                    .cancelNotificationsByChannelKey("chat_channel_key");
                AwesomeNotifications()
                    .cancelNotificationsByGroupKey("chat_channel_group_key");
              }
            },
            items: tabs.map((e) => e.navigationBarItem).toList(),
          ),
          floatingActionButton:
              tabs[controller.currentTabIndex.value].floatingActionButton,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      }),
    );
  }
}
