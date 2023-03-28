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
import 'package:roomy_finder/functions/share_app.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/blog_post/all_posts.dart';
import 'package:roomy_finder/screens/home/account_tab.dart';
import 'package:roomy_finder/screens/home/favorites_tab.dart';
import 'package:roomy_finder/screens/home/home_tab.dart';
import 'package:roomy_finder/screens/home/chat_tab.dart';
import 'package:roomy_finder/screens/home/maintenance_tab.dart';
import 'package:roomy_finder/screens/user/contact_us.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/user/view_pdf.dart';
import 'package:roomy_finder/screens/utility_screens/update_app.dart';
import 'package:roomy_finder/utilities/data.dart';

class HomeController extends LoadingController {
  final currentTabIndex = 0.obs;
  Timer? _popTimer;
  int _popClickCounts = 0;
  final tabs = <HomeScreenSupportable>[];

  @override
  void onInit() {
    tabs.addAll(const [
      HomeTab(),
      AccountTab(),
      MessagesTab(),
      FavoriteTab(),
    ]);
    if (AppController.me.isLandlord) {
      tabs.add(const MaintenanceTab());
    }
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return WillPopScope(
      onWillPop: controller._onWillPop,
      child: Obx(() {
        return Scaffold(
          appBar: controller.tabs[controller.currentTabIndex.value].appBar,
          drawer: SafeArea(
            child: HomeDrawer(controller: controller),
          ),
          body: LazyLoadIndexedStack(
            index: controller.currentTabIndex.value,
            children: controller.tabs,
          ),
          bottomNavigationBar: AppController.me.isGuest
              ? null
              : BottomNavigationBar(
                  currentIndex: controller.currentTabIndex.value,
                  onTap: (index) {
                    controller.currentTabIndex(index);
                    if (index == 2) {
                      final chatController = Get.put(ChatTabController());
                      chatController.update();
                      AppController.instance.haveNewMessage(false);
                      AwesomeNotifications()
                          .cancelNotificationsByChannelKey("chat_channel_key");
                      AwesomeNotifications().cancelNotificationsByGroupKey(
                        "chat_channel_group_key",
                      );
                    }
                  },
                  items:
                      controller.tabs.map((e) => e.navigationBarItem).toList(),
                ),
          floatingActionButton: controller
              .tabs[controller.currentTabIndex.value].floatingActionButton,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      }),
    );
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (!AppController.me.isGuest)
              AppController.me.ppWidget(borderColor: false),
            if (!AppController.me.isGuest)
              Text(
                AppController.me.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            if (!AppController.me.isGuest)
              Builder(builder: (context) {
                final type = AppController.me.type;
                if (type.isEmpty) return const SizedBox();
                return Text(
                  type.replaceFirst(type[0], type[0].toUpperCase()),
                  style: const TextStyle(),
                );
              }),
            if (!AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                title: const Text("Edit Profile"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.back();
                  Get.to(() => const UpdateUserProfile());
                },
              ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  "General Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ROOMY_ORANGE,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: const Text("My Account"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  controller.currentTabIndex(1);
                  Get.back();
                },
              ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Icon(Icons.add_box, color: Colors.white),
              ),
              title: const Text("Post Ad"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                if (AppController.me.isGuest) {
                  Get.offAllNamed('/login');
                } else if (AppController.me.isLandlord) {
                  Get.to(() => const PostPropertyAdScreen());
                } else if (AppController.me.isRoommate) {
                  Get.to(() {
                    return const PostRoommateAdScreen(
                      isPremium: true,
                    );
                  });
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pink,
                child: Icon(Icons.support_agent, color: Colors.white),
              ),
              title: const Text("Contact Us"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() => const ContactUsScreen());
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: ROOMY_ORANGE,
                child: Icon(Icons.article, color: Colors.white),
              ),
              title: const Text("Blog"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() => const AllBlogPostsScreen());
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(Icons.info_outline, color: Colors.white),
              ),
              title: const Text("Terms & Conditions"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() {
                  return const ViewPdfScreen(
                    title: "Terms and conditions",
                    asset: "assets/pdf/terms-and-conditions.pdf",
                  );
                });
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.red,
                child: Icon(Icons.privacy_tip, color: Colors.white),
              ),
              title: const Text("Privacy Policy"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() {
                  return const ViewPdfScreen(
                    title: "Privacy policy",
                    asset: "assets/pdf/privacy-policy.pdf",
                  );
                });
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purpleAccent,
                child: Icon(Icons.share, color: Colors.white),
              ),
              title: const Text("Share This App"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                shareApp();
              },
            ),
          ],
        ),
      ),
    );
  }
}
