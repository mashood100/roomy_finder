import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';

// ignore: unused_element
class _MaintenanceTabController extends LoadingController {}

class MaintenanceTab extends StatelessWidget implements HomeScreenSupportable {
  const MaintenanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(_MaintenanceTabController());
    return const Center(child: Text("Coming soon"));
  }

  @override
  AppBar get appBar {
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      title: const Text('Maintenance'),
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: const Icon(CupertinoIcons.settings),
      label: 'Maintenance'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
