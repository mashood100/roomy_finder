import 'dart:async';

import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/maintenance/screens/find_maintenances.dart';
import 'package:roomy_finder/maintenance/screens/maintenant/my_offers.dart';
import 'package:roomy_finder/maintenance/screens/my_maintenances.dart';
import 'package:roomy_finder/maintenance/screens/request/request_maintenance.dart';
import 'package:roomy_finder/screens/messages/view_notifications.dart';
import 'package:roomy_finder/screens/user/balance.dart';
import 'package:roomy_finder/screens/user/view_profile.dart';

class MaintenanceHome extends StatefulWidget {
  const MaintenanceHome({super.key});

  @override
  State<MaintenanceHome> createState() => _MaintenanceHomeState();
}

class _MaintenanceHomeState extends State<MaintenanceHome> {
  int _popClickCounts = 0;
  Timer? _popTimer;

  @override
  void dispose() {
    if (_popTimer != null) _popTimer!.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!AppController.me.isMaintenant) return true;

        if (_popClickCounts > 0) return true;

        _popClickCounts++;
        showToast("clickAgainToQuitApp".tr);
        _popTimer =
            Timer(const Duration(seconds: 2), () => _popClickCounts = 0);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("MAINTENANCE"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              if (AppController.me.isMaintenant)
                Card(
                  child: ListTile(
                    onTap: () {
                      Get.to(() => const FindMaintenancesScreen());
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundImage:
                          AssetImage("assets/maintenance/repair_1.png"),
                    ),
                    title: const Text('Maintenances offers'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              if (AppController.me.isLandlord)
                Card(
                  child: ListTile(
                    onTap: () {
                      Get.to(() => const RequestMaintenanceScreen());
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundImage:
                          AssetImage("assets/maintenance/repair_2.png"),
                    ),
                    title: const Text('Request Maintenance'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              if (AppController.me.isLandlord)
                Card(
                  child: ListTile(
                    onTap: () {
                      Get.to(() => const MyMaintenancesScreen());
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundImage:
                          AssetImage("assets/maintenance/repair_1.png"),
                    ),
                    title: const Text('My Maintenances'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              // For Maintenant
              if (AppController.me.isMaintenant)
                Card(
                  child: ListTile(
                    onTap: () {
                      Get.to(() => const MyOffersScreen());
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      foregroundImage:
                          AssetImage("assets/maintenance/repair_2.png"),
                    ),
                    title: const Text('MY Offers'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),

              if (AppController.me.isMaintenant) const Divider(),
              if (AppController.me.isMaintenant)
                Card(
                  child: ListTile(
                    onTap: () => Get.to(() => const NotificationsScreen()),
                    leading: AppController.me.ppWidget(size: 25),
                    title: Text(AppController.me.fullName),
                    subtitle: const Text("See profile"),
                    trailing: IconButton(
                      onPressed: () {
                        Get.to(() => const ViewProfileScreen());
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              if (AppController.me.isMaintenant)
                Card(
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
              if (AppController.me.isMaintenant)
                Card(
                  child: ListTile(
                    onTap: () => Get.to(() => const NotificationsScreen()),
                    leading: Obx(() {
                      var badge =
                          AppController.instance.badges["notifications"];
                      return Badge(
                        badgeContent: Text(badge.toString()),
                        showBadge: badge! > 0,
                        child: const CircleAvatar(
                          backgroundColor: Colors.transparent,
                          foregroundImage:
                              AssetImage("assets/icons/notification.png"),
                        ),
                      );
                    }),
                    title: const Text('Notifications'),
                    trailing: IconButton(
                      onPressed: () {
                        Get.to(() => const NotificationsScreen());
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              if (AppController.me.isMaintenant)
                Card(
                  child: ListTile(
                    title: const Text("Logout"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      _logout(Get.context!);
                    },
                    leading: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
