import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/utilities/data.dart';

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
        icon: Image.asset(
          "assets/icons/add_square.png",
          height: 30,
          width: 30,
          color: ROOMY_PURPLE,
        ),
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
