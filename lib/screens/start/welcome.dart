import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/app_locale.dart';
import 'package:roomy_finder/screens/start/login.dart';

class _WelcomeScreenController extends GetxController {
  late final PageController _pageController;

  final _pageIndex = 0.obs;

  @override
  void onInit() {
    _pageController = PageController();
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();

    super.onClose();
  }

  @override
  void onReady() {
    precacheImage(
      const AssetImage("assets/images/welcome.png"),
      Get.context!,
    );
    super.onReady();
  }

  // void _toggleThemeMode() {
  //   AppController.setThemeMode(
  //       Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  //   Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  // }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_WelcomeScreenController());
    return Scaffold(
      // appBar: AppBar(toolbarHeight: 0),
      body: PageView(
        onPageChanged: controller._pageIndex,
        physics: const NeverScrollableScrollPhysics(),
        controller: controller._pageController,
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/flyer_roomy_finder.jpeg',
                // height: 100,
                // width: 100,
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    // Padding(
                    //   padding: const EdgeInsets.all(20),
                    //   child: Center(
                    //     child: ClipRRect(
                    //       borderRadius: const BorderRadius.only(
                    //           // bottomRight: Radius.circular(10),
                    //           // bottomLeft: Radius.circular(10),
                    //           ),
                    //       child: Image.asset(
                    //         'assets/images/flyer_roomy_finder.jpeg',
                    //         // height: 100,
                    //         // width: 100,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 30),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 10),
                    //   child: Text(
                    //     'welcomeToRoomyFinder'.tr,
                    //     style: const TextStyle(
                    //       fontSize: 24,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 10),
                    //   child: Text('roomyFinderDescriptionText'.tr),
                    // ),
                    // const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            key: const Key("start-key"),
            children: [
              // CircleAvatar(
              //   backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              //   child: IconButton(
              //     onPressed: controller._toggleThemeMode,
              //     icon: Theme.of(context).brightness == Brightness.light
              //         ? const Icon(Icons.dark_mode)
              //         : const Icon(Icons.light_mode),
              //   ),
              // ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => changeAppLocale(context),
                label: Text('language'.tr),
                icon: const Icon(Icons.language),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const LoginScreen());
                },
                child: Text('letGo'.tr),
              ),
            ],
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
