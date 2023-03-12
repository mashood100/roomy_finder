import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';

// ignore: unused_element
class _FavoriteTabController extends LoadingController {}

class FavoriteTab extends StatelessWidget implements HomeScreenSupportable {
  const FavoriteTab({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(_FavoriteTabController());
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: const [
            Text('Empty list'),
          ],
        ),
      ),
    );
  }

  @override
  AppBar get appBar {
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      automaticallyImplyLeading: false,
      title: const Text('Favorites'),
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: const Icon(CupertinoIcons.heart_fill),
      label: 'Favorites'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
