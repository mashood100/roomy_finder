import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/my_roommate_ads.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/screens/user/about.dart';
import 'package:roomy_finder/screens/user/view_user.dart';

class _AccountTabController extends LoadingController {
  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Roomy Finder'),
            content: const Text("Do you really want to logout?"),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // const HomeUserInfo(),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: const Text('My account'),
                trailing: IconButton(
                  onPressed: () {
                    Get.to(() => ViewUser(user: AppController.me));
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            ),
            if (AppController.me.isLandlord)
              Card(
                child: ListTile(
                  onTap: () => Get.to(() => const MyPropertyAdsScreen()),
                  leading: const CircleAvatar(
                    child: Icon(Icons.widgets),
                  ),
                  title: const Text('My Property Ads'),
                  trailing: IconButton(
                    onPressed: () => Get.to(() => const MyPropertyAdsScreen()),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            Card(
              child: ListTile(
                onTap: () => Get.to(() => const MyRoommateAdsScreen()),
                leading: const CircleAvatar(
                  child: Icon(Icons.houseboat),
                ),
                title: const Text('My Premium Ads, Roommate match'),
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
                  child: Icon(Icons.book),
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
                leading: const CircleAvatar(child: Icon(Icons.info_outlined)),
                title: const Text('About'),
                trailing: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.chevron_right),
                ),
              ),
            ),

            // Card(
            //   child: ListTile(
            //     onTap: () => controller._logout(context),
            //     leading: CircleAvatar(
            //       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            //       child: const Icon(Icons.logout, color: Colors.red),
            //     ),
            //     title: Text('logout'.tr),
            //     textColor: Colors.red,
            //     trailing: const Icon(Icons.chevron_right),
            //   ),
            // ),
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
      automaticallyImplyLeading: false,
      title: const Text('Accout'),
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => controller._logout(Get.context!),
          icon: const Icon(Icons.logout, color: Colors.red),
        )
      ],
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: const Icon(CupertinoIcons.person_alt_circle_fill),
      label: 'account'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
