import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/my_roommate_ads.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/screens/messages/view_notifications.dart';
import 'package:roomy_finder/screens/user/about.dart';
import 'package:roomy_finder/screens/user/view_profile.dart';
import 'package:roomy_finder/utilities/data.dart';

class _AccountTabController extends LoadingController {
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

class AccountTab extends StatelessWidget implements HomeScreenSupportable {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = AppController.me;
    Get.put(_AccountTabController());
    return Padding(
      padding: const EdgeInsets.symmetric(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Obx(() {
              return SizedBox(
                width: Get.width - 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => CachedNetworkImage(
                            imageUrl: AppController.me.profilePicture,
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 60,
                        foregroundImage: CachedNetworkImageProvider(
                          AppController.instance.user.value.profilePicture,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: Get.width * 0.5,
                          child: Text(
                            me.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: Get.width * 0.5,
                          child: Text(
                            me.type.replaceFirst(
                              me.type[0],
                              me.type[0].toUpperCase(),
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              color: Get.theme.appBarTheme.backgroundColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Get.to(() => const ViewProfileScreen());
                          },
                          icon: Icon(me.gender == "Male"
                              ? Icons.person
                              : Icons.person_4),
                          label: const Text("All details"),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Card(
              child: ListTile(
                onTap: () => Get.to(() => const NotificationsScreen()),
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.notifications,
                    color: ROOMY_ORANGE,
                  ),
                ),
                title: const Text('Notifications'),
                subtitle: Text(
                  "${AppController.instance.unreadNotificationCount}"
                  " unread notifications",
                ),
                trailing: IconButton(
                  onPressed: () {
                    Get.to(() => const NotificationsScreen());
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            ),
            // if (me.isLandlord)
            //   ListTile(
            //     leading: const CircleAvatar(
            //       child: Icon(CupertinoIcons.money_dollar_circle),
            //     ),
            //     title: const Text('Accout balance'),
            //     subtitle: Text(formatMoney(0)),
            //     trailing: IconButton(
            //       onPressed: () {},
            //       icon: const Icon(Icons.chevron_right),
            //     ),
            //   ),
            if (AppController.me.isLandlord)
              Card(
                child: ListTile(
                  onTap: () => Get.to(() => const MyPropertyAdsScreen()),
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.widgets,
                      color: ROOMY_ORANGE,
                    ),
                  ),
                  title: const Text('My Ads'),
                  trailing: IconButton(
                    onPressed: () => Get.to(() => const MyPropertyAdsScreen()),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            if (AppController.me.isRoommate)
              Card(
                child: ListTile(
                  onTap: () => Get.to(() => const MyRoommateAdsScreen()),
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.houseboat,
                      color: ROOMY_ORANGE,
                    ),
                  ),
                  title: const Text('My Ads'),
                  trailing: IconButton(
                    onPressed: () {
                      Get.to(() => const MyRoommateAdsScreen());
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            Card(
              child: ListTile(
                onTap: () => Get.to(() => const MyBookingsCreen()),
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.book,
                    color: ROOMY_ORANGE,
                  ),
                ),
                title: const Text('My Bookings'),
                trailing: IconButton(
                  onPressed: () {
                    Get.to(() => const MyBookingsCreen());
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () {
                  Get.to(() => const AboutScreeen());
                },
                leading: const CircleAvatar(
                    child: Icon(
                  Icons.info_outlined,
                  color: ROOMY_ORANGE,
                )),
                title: const Text('About'),
                trailing: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.chevron_right),
                ),
              ),
            ),
            // ListTile(
            //   onTap: () => controller._logout(context),
            //   leading: const CircleAvatar(
            //     child: Icon(Icons.logout, color: Colors.red),
            //   ),
            //   title: Text('Logout'.tr),
            //   textColor: Colors.red,
            //   trailing: const IconButton(
            //     onPressed: null,
            //     icon: Icon(Icons.chevron_right),
            //   ),
            // ),
            // const Divider(),
            Row(
              children: const [],
            )
          ],
        ),
      ),
    );
  }

  @override
  AppBar get appBar {
    final controller = Get.put(_AccountTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      title: const Text('My Account'),
      centerTitle: false,
      elevation: 0,
      actions: [
        SizedBox(
          height: 35,
          child: OutlinedButton.icon(
            onPressed: () => controller._logout(Get.context!),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        )
      ],
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      activeIcon: Image.asset("assets/icons/account.png", height: 30),
      icon: Image.asset("assets/icons/account_white.png", height: 30),
      label: 'Account'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
