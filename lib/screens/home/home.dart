import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
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
import 'package:roomy_finder/screens/home/post_ad_tab.dart';
import 'package:roomy_finder/screens/utility_screens/contact_us.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/utility_screens/view_pdf.dart';
import 'package:roomy_finder/screens/utility_screens/update_app.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeController extends LoadingController {
  late final StreamSubscription<FGBGType> fGBGNotifierSubScription;
  final currentTabIndex = 1.obs;
  Timer? _popTimer;
  int _popClickCounts = 0;
  final List<HomeScreenSupportable> tabs = [
    const AccountTab(),
    const HomeTab(),
    const PostAdTab(),
    const MessagesTab(),
    const FavoriteTab(),
  ];

  @override
  void onInit() {
    fGBGNotifierSubScription = FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground) {
        if (ChatConversation.homeTabIsChat = true) {
          AwesomeNotifications().cancelAll();
        }
      }
    });

    AppController.instance.setIsFirstLaunchToFalse(false);

    if (AppController.dynamicInitialLink != null) {
      dynamicLinkHandler(AppController.dynamicInitialLink!);
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
          if (currentTabIndex.value == 3) {
            AwesomeNotifications().cancelAll();
          } else {
            AppController.instance.haveNewMessage(true);
          }

          break;
        default:
      }
    });
  }

  @override
  void onClose() {
    if (_popTimer != null) _popTimer!.cancel();
    fGBGNotifierSubScription.cancel();
    super.onClose();
  }

  // Initial Remote message handler
  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      if (AppController.me.isGuest) return;
      if (AppController.haveOpenInitialMessage) return;
      NotificationController.onFCMMessageOpenedAppHandler(message);
    }
    await NotificationController.requestNotificationPermission(Get.context);
    AppController.haveOpenInitialMessage = true;
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

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Roomy Finder'),
            content: const Text("Are you sure yo want to logout?"),
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
    if (shouldLogout == true) {
      AppController.instance.logout();
      Get.offAllNamed('/login');
    }
  }
}

class Home extends GetView<HomeController> {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController(), permanent: true);
    return WillPopScope(
      onWillPop: controller._onWillPop,
      child: Obx(() {
        return Scaffold(
          appBar: controller.tabs[controller.currentTabIndex.value].appBar,
          drawer: SafeArea(
            child: HomeDrawer(controller: controller),
          ),
          body: IndexedStack(
            index: controller.currentTabIndex.value,
            children: controller.tabs,
          ),
          bottomNavigationBar: AppController.me.isGuest
              ? null
              : BottomNavigationBar(
                  currentIndex: controller.currentTabIndex.value,
                  onTap: (index) {
                    if (controller.tabs[index] is MessagesTab) {
                      ChatConversation.homeTabIsChat = true;
                    } else {
                      ChatConversation.homeTabIsChat = false;
                    }

                    controller.tabs[index].onIndexSelected(index);
                    if (controller.tabs[index] is PostAdTab) {
                      if (AppController.me.isGuest) {
                        Get.offAllNamed('/login');
                      } else if (AppController.me.isLandlord) {
                        Get.to(() => const PostPropertyAdScreen());
                      } else if (AppController.me.isRoommate) {
                        Get.to(() => const PostRoommateAdScreen());
                      }
                      // showToast("Comming soon");
                      return;
                    }

                    controller.currentTabIndex(index);
                  },
                  items: controller.tabs.map((e) {
                    return e.navigationBarItem(
                        controller.currentTabIndex.value ==
                            controller.tabs.indexOf(e));
                  }).toList(),
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
            if (AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ROOMY_ORANGE,
                  child: Icon(Icons.login, color: Colors.white),
                ),
                title: const Text("Login"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.offAllNamed("/login");
                },
              ),
            if (AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ROOMY_PURPLE,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: const Text("Register"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.offAllNamed("/login");
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
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: ROOMY_PURPLE,
                child: Icon(Icons.home, color: Colors.white),
              ),
              title: const Text("Home"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.currentTabIndex(1);
                Get.back();
              },
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
                  controller.currentTabIndex(0);
                  Get.back();
                },
              ),
            ListTile(
              // ),
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
                    return const PostRoommateAdScreen();
                  });
                }
              },
            ),
            ListTile(
              // leading: Image.asset(
              //   "assets/icons/drawer/contact_us.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
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
              // leading: Image.asset(
              //   "assets/icons/drawer/edit_article.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
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
              // leading: Image.asset(
              //   "assets/icons/drawer/info.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
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
              // leading: Image.asset(
              //   "assets/icons/drawer/lock.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
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
              // leading: Image.asset(
              //   "assets/icons/drawer/share.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
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
            if (!AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.logout, color: Colors.white),
                ),
                title: const Text("Logout"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.back();
                  controller._logout(Get.context!);
                },
              ),
            const Divider(height: 10),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                {
                  "url":
                      "https://www.tiktok.com/@roomyfinder?_t=8bNtaBqPwQr&_r=1",
                  "assetImage": "assets/images/social/tiktok.png",
                  "label": "Tiktok",
                },
                {
                  "url": "https://www.facebook.com/roomyfinder?mibextid=LQQJ4d",
                  "assetImage": "assets/images/social/facebook.png",
                  "label": "Facebook",
                },
                {
                  "url":
                      "https://instagram.com/roomyfinder?igshid=YjNmNGQ3MDY=",
                  "assetImage": "assets/images/social/instagram.png",
                  "label": "Instagram",
                },
                {
                  "assetImage": "assets/images/social/twitter.png",
                  "label": "Twitter",
                },
                {
                  "assetImage": "assets/images/social/snapchat.png",
                  "label": "Snapchat",
                },
              ].map((e) {
                return GestureDetector(
                  onTap: () async {
                    Get.back();
                    if (e["url"] == null) {
                      showToast("Comming soon...");
                      return;
                    }
                    var url = Uri.parse(e["url"]!);
                    if (await canLaunchUrl(url)) {
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Image.asset(e["assetImage"]!, width: 40, height: 40),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
