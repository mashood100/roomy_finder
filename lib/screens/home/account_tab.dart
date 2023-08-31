import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/drawer.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/my_roommate_ads.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/screens/user/favorites_ads.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/screens/utility_screens/view_notifications.dart';
import 'package:roomy_finder/screens/user/account_balance.dart/balance.dart';
import 'package:roomy_finder/screens/utility_screens/about.dart';
import 'package:roomy_finder/screens/user/view_profile.dart';
import 'package:roomy_finder/utilities/data.dart';

class AccountTab extends StatelessWidget implements HomeScreenSupportable {
  const AccountTab({super.key});

  @override
  void onTabIndexSelected(int index) {}

  @override
  Widget build(BuildContext context) {
    final me = AppController.me;
    return Scaffold(
      drawer: const HomeDrawer(),
      appBar: AppBar(
        backgroundColor: ROOMY_PURPLE,
        title: const Text('My Account'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Builder(builder: (context) {
              return SizedBox(
                width: Get.width - 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (AppController.me.profilePicture == null) return;

                        Get.to(() {
                          return ViewImages(
                            images: [
                              CachedNetworkImageProvider(
                                AppController.me.profilePicture!,
                              )
                            ],
                          );
                        });
                      },
                      child: Obx(() {
                        final ImageProvider provider;

                        if (AppController.instance.user.value.profilePicture ==
                            null) {
                          provider = AssetImage(
                            AppController.me.gender == "Male"
                                ? "assets/images/default_male.png"
                                : "assets/images/default_female.png",
                          );
                        } else {
                          provider = CachedNetworkImageProvider(
                            AppController.instance.user.value.profilePicture!,
                          );
                        }
                        return CircleAvatar(
                          radius: 60,
                          foregroundImage: provider,
                        );
                      }),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() {
                            var me = AppController.instance.user.value;
                            return Text(
                              me.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            );
                          }),
                          Builder(builder: (context) {
                            final type = AppController.me.type;
                            if (type.isEmpty) return const SizedBox();
                            return Text(
                              type.replaceFirst(type[0], type[0].toUpperCase()),
                              style: const TextStyle(),
                            );
                          }),
                          OutlinedButton.icon(
                            onPressed: () {
                              Get.to(() => const ViewProfileScreen());
                            },
                            icon: Icon(
                              me.gender == "Male"
                                  ? Icons.person
                                  : Icons.person_4,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              "All details",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            if (AppController.me.isRoommate)
              Card(
                surfaceTintColor: Colors.white,
                child: ListTile(
                  onTap: () => Get.to(() => const NotificationsScreen()),
                  leading: Obx(() {
                    var badge = Home.unReadNotificationsCount.value;
                    return Badge.count(
                      count: badge,
                      isLabelVisible: badge > 0,
                      child: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        foregroundImage: AssetImage(AssetIcons.notificationPNG),
                      ),
                    );
                  }),
                  title: const Text('Notifications'),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            Card(
              surfaceTintColor: Colors.white,
              child: ListTile(
                onTap: () {
                  if (AppController.me.isLandlord) {
                    if (AppController.dashboardIsBlocked) {
                      RoomyNotificationHelper.showDashBoardIsBlocked();
                      return;
                    }
                    Get.to(() => const MyPropertyAdsScreen());
                  } else if (AppController.me.isRoommate) {
                    Get.to(() => const MyRoommateAdsScreen());
                  }
                },
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage(AssetIcons.adPNG),
                ),
                title: const Text('My Ads'),
                trailing: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.chevron_right),
                ),
              ),
            ),
            Card(
              surfaceTintColor: Colors.white,
              child: ListTile(
                onTap: () => Get.to(() => const FavoriteScreen()),
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage(AssetIcons.favorite2PNG),
                ),
                title: const Text('My Favorites'),
                trailing: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.chevron_right),
                ),
              ),
            ),
            // if (AppController.me.isLandlord)
            //   Card( surfaceTintColor: Colors.white,
            //     child: ListTile(
            //       onTap: () => Get.toNamed("/maintenance"),
            //       leading: Obx(() {
            //         var badge = Maintenance.notificationsCount.value;
            //         return Badge(
            //           badgeContent: Text(badge.toString()),
            //           showBadge: badge > 0,
            //           child: const CircleAvatar(
            //             backgroundColor: Colors.transparent,
            //             foregroundImage:
            //                 AssetImage("assets/maintenance/maintenace.png"),
            //           ),
            //         );
            //       }),
            //       title: const Text('Maintenance'),
            //       trailing: const IconButton(
            //         onPressed: null,
            //         icon: Icon(Icons.chevron_right),
            //       ),
            //     ),
            //   ),
            Card(
              surfaceTintColor: Colors.white,
              child: ListTile(
                onTap: () {
                  Get.to(() => const AboutScreeen());
                },
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage(AssetIcons.infoPNG),
                ),
                title: const Text('About'),
                trailing: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.chevron_right),
                ),
              ),
            ),
            if (AppController.me.isLandlord)
              Card(
                surfaceTintColor: Colors.white,
                child: ListTile(
                  title: const Text("Account Balance"),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                  onTap: () {
                    Get.to(() => const UserBalanceScreen());
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundImage: AssetImage("assets/icons/wallet.png"),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const HomeBottomNavigationBar(),
    );
  }
}
