import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';

// ignore: unused_element
class _PostAdTabController extends LoadingController {}

class PostAdTab extends StatelessWidget implements HomeScreenSupportable {
  const PostAdTab({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(_PostAdTabController());
    return const Center();
  }

  @override
  AppBar? get appBar => AppBar();

  @override
  BottomNavigationBarItem navigationBarItem(isCurrent) {
    return BottomNavigationBarItem(
      icon: CustomBottomNavbarIcon(
        icon: const Icon(CupertinoIcons.plus_app),
        isCurrent: isCurrent,
      ),
      label: 'Post Ad'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {}
}
