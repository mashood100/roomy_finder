import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/functions/check_for_update.dart';
import 'package:roomy_finder/functions/dynamic_link_handler.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/chat_conversation_v2.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_ad_first_screen.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/screens/home/account_tab.dart';
import 'package:roomy_finder/screens/home/home_tab.dart';
import 'package:roomy_finder/screens/home/conversations_tab.dart';
import 'package:roomy_finder/screens/home/landlord_dashboard.dart';
import 'package:roomy_finder/screens/home/post_ad_tab.dart';
import 'package:roomy_finder/screens/utility_screens/update_app.dart';
import 'package:roomy_finder/screens/utility_screens/view_notifications.dart';

class _HomeController extends LoadingController {
  late final StreamSubscription<RemoteMessage> fcmStream;
  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;

  Timer? _popTimer;
  int _popClickCounts = 0;

  @override
  void onInit() {
    Future(() => Home.currentIndex(1));
    ApiService.setUnreadBookingCount();
    ApiService.setLanlordIsBlocked();
    AppController.instance.setIsFirstLaunchToFalse(false);

    if (AppController.dynamicInitialLink != null) {
      dynamicLinkHandler(AppController.dynamicInitialLink!);
    }

    Future(_runStartFutures);

    Future.delayed(const Duration(seconds: 1), _handleInitialMessage);

    super.onInit();

    FirebaseMessaging.instance.subscribeToTopic("new-property-ad");
    FirebaseMessaging.instance.subscribeToTopic("new-roommate-ad");

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        ApiService.setUnreadBookingCount();
      }
    });

    fcmStream =
        FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;
      // AppController.instance.haveNewMessage(false);

      if (data["event"]?.toString().contains("booking") == true) {
        ApiService.setUnreadBookingCount();
      }
      switch (data["event"]) {
        case "plan-upgraded-successfully":
          AppController.instance.user.update((val) {
            if (val != null) val.isPremium = true;
          });
          showToast("Plan successfully upgraded to premium");

          break;

        case "account-updated":
          ApiService.updateUserProfile();

          break;

        default:
      }
    });
  }

  @override
  void onClose() {
    if (_popTimer != null) _popTimer!.cancel();
    super.onClose();
    fcmStream.cancel();
    _fGBGNotifierSubScription.cancel();
    Home.unViewBookingsCount.value = 0;
  }

  // Initial Remote message handler
  Future<void> _handleInitialMessage() async {
    if (AppController.me.isGuest) return;
    if (AppController.haveOpenInitialMessage) return;

// FCM initial message
    final fcmMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (fcmMessage != null) {
      NotificationController.handleFCMMessageOpenedAppMessage(fcmMessage);
    }

// Local notification initial message
    final launchNot =
        await NotificationController.plugin.getNotificationAppLaunchDetails();

    if (launchNot != null && launchNot.didNotificationLaunchApp) {
      NotificationController.handleInitialMessage(
          launchNot.notificationResponse!);
    }

    AppController.haveOpenInitialMessage = true;
  }

  Future<void> _runStartFutures() async {
    await _promptUpdate();
    await LocalNotificationController.requestNotificationPermission();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
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
}

class Home extends StatelessWidget {
  static final currentIndex = 1.obs;
  static final RxInt unViewBookingsCount = 0.obs;
  static final RxInt unreadMessagesCount = 0.obs;
  static final RxInt unReadNotificationsCount = 0.obs;

  static List<({String assetIcon, RxInt badge, String label})> get _tabs => [
        (
          label: 'Account',
          assetIcon: AssetIcons.personPNG,
          badge: 0.obs,
        ),
        (
          label: 'Home',
          assetIcon: AssetIcons.homePNG,
          badge: 0.obs,
        ),
        if (AppController.me.isRoommate)
          (
            label: 'Post Ad',
            assetIcon: AssetIcons.addSquarePNG,
            badge: 0.obs,
          ),
        (
          label: 'Chat',
          assetIcon: AssetIcons.chatPNG,
          badge: unreadMessagesCount,
        ),
        if (AppController.me.isRoommate)
          (
            label: 'My Bookings',
            assetIcon: AssetIcons.squareCheckedPNG,
            badge: unViewBookingsCount,
          ),
        if (AppController.me.isLandlord)
          (
            label: 'Notifications',
            assetIcon: AssetIcons.notification2PNG,
            badge: unReadNotificationsCount,
          ),
      ];

  static List<HomeScreenSupportable> get _screens => [
        const AccountTab(),
        if (AppController.me.isRoommate)
          const HomeTab()
        else
          const LandlordHomeTab(),
        if (AppController.me.isRoommate) const PostAdTab(),
        const ChatConversationsTab(),
        if (AppController.me.isRoommate)
          const MyBookingsCreen(showNavBar: true),
        if (AppController.me.isLandlord)
          const NotificationsScreen(showNavBar: true)
      ];

  static void _onBottomTabItemSelected(int index) {
    if (AppController.dashboardIsBlocked &&
        AppController.me.isLandlord &&
        (index == 2 || index == 3)) {
      RoomyNotificationHelper.showDashBoardIsBlocked();
      return;
    }
    if (_tabs[index] is ChatConversationsTab) {
      ChatConversationV2.homeTabIsChat = true;
    } else {
      ChatConversationV2.homeTabIsChat = false;
    }

    _screens[index].onTabIndexSelected(index);

    if (_screens[index] is PostAdTab) {
      if (AppController.me.isGuest) {
        Get.offAllNamed('/login');
      } else if (AppController.me.isLandlord) {
        Get.to(() => const PostPropertyAdScreen());
      } else if (AppController.me.isRoommate) {
        Get.to(() => const PostRoommateAdFirstScreen());
      }
      // showToast("Comming soon");
      return;
    }
    currentIndex(index);
  }

  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_HomeController(), permanent: true);
    return WillPopScope(
      onWillPop: controller._onWillPop,
      child: Obx(() => IndexedStack(
            index: Home.currentIndex.value,
            children: Home._screens,
          )),
    );
  }
}

class HomeBottomNavigationBar extends StatelessWidget {
  const HomeBottomNavigationBar({super.key, this.onTap});
  final void Function(int)? onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return BottomNavigationBar(
        currentIndex: Home.currentIndex.value,
        onTap: (index) {
          Home._onBottomTabItemSelected(index);

          if (onTap != null) onTap!(index);
        },
        items: Home._tabs.map((e) {
          final isCurrent = Home.currentIndex.value == Home._tabs.indexOf(e);
          return BottomNavigationBarItem(
            icon: CustomBottomNavbarIcon(
              assetIcon: e.assetIcon,
              isCurrent: isCurrent,
              badge: e.badge.value,
            ),
            label: e.label,
          );
        }).toList(),
      );
    });
  }
}
