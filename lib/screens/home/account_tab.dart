import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/my_roommate_ads.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/screens/messages/view_notifications.dart';
import 'package:roomy_finder/screens/user/withdraw.dart';
import 'package:roomy_finder/screens/utility_screens/about.dart';
import 'package:roomy_finder/screens/user/view_profile.dart';
import 'package:roomy_finder/utilities/data.dart';

class _AccountTabController extends LoadingController {}

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
            Builder(builder: (context) {
              return SizedBox(
                width: Get.width - 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (AppController.me.profilePicture == null) return;
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => CachedNetworkImage(
                            imageUrl: AppController.me.profilePicture!,
                          ),
                        );
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            textAlign: TextAlign.center,
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
                            textAlign: TextAlign.center,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Get.to(() => const ViewProfileScreen());
                          },
                          icon: Icon(
                            me.gender == "Male" ? Icons.person : Icons.person_4,
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
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage("assets/icons/notification.png"),
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
            Card(
              child: ListTile(
                onTap: () {
                  if (AppController.me.isLandlord) {
                    Get.to(() => const MyPropertyAdsScreen());
                  } else if (AppController.me.isRoommate) {
                    Get.to(() => const MyRoommateAdsScreen());
                  }
                },
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage("assets/icons/ad.png"),
                ),
                title: const Text('My Ads'),
                trailing: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.chevron_right),
                ),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () => Get.to(() => const MyBookingsCreen()),
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage("assets/icons/booking.png"),
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
                  backgroundColor: Colors.transparent,
                  foregroundImage: AssetImage("assets/icons/info.png"),
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
                child: ListTile(
                  title: const Text("Account balance"),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                  onTap: () {
                    Get.to(() => const WithdrawScreen());
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundImage: AssetImage("assets/icons/wallet.png"),
                  ),
                ),
              ),
            if (AppController.me.isLandlord)
              Card(
                child: ListTile(
                  onTap: () {
                    showToast("Coming soon...");
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    foregroundImage: AssetImage("assets/icons/wallet.png"),
                  ),
                  title: const Text('Roomy balance'),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            if (AppController.me.isRoommate)
              Card(
                child: ListTile(
                  onTap: () {
                    showToast("Coming soon...");
                  },
                  //leading: const CircleAvatar(
                  // backgroundColor: Colors.white,
                  //     child: Icon(
                  //   Icons.info_outlined,
                  //   color: ROOMY_ORANGE,
                  // )),
                  title: const Text('Roomy wallet'),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                ),
              ),
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
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      title: const Text('My Account'),
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  BottomNavigationBarItem navigationBarItem(isCurrent) {
    return BottomNavigationBarItem(
      icon: CustomBottomNavbarIcon(
        icon: Image.asset(
          "assets/icons/person.png",
          height: 30,
          width: 30,
          color: ROOMY_PURPLE,
        ),
        isCurrent: isCurrent,
      ),
      label: 'Account'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {}
}
