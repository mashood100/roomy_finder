import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/app_locale.dart';
import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/start/registration.dart';

class _WelcomeScreenController extends GetxController {
  late final PageController _pageController;
  _WelcomeScreenController(this.pageIndex);
  final int? pageIndex;

  final _pageIndex = 0.obs;

  @override
  void onInit() {
    _pageController = PageController(initialPage: pageIndex ?? 0);
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
    precacheImage(
      const AssetImage("assets/images/dubai-city.jpg"),
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
  const WelcomeScreen({super.key, this.pageIndex});
  final int? pageIndex;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_WelcomeScreenController(pageIndex));
    return Scaffold(
      // appBar: AppBar(toolbarHeight: 0),
      body: PageView(
        controller: controller._pageController,
        onPageChanged: controller._pageIndex,
        // physics: const NeverScrollableScrollPhysics(),
        children: [
          Image.asset(
            "assets/images/flyer_roomy_finder.jpeg",
            width: Get.width,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.asset(
                "assets/images/dubai-city.jpg",
                width: Get.width,
                height: Get.height,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              // Container(
              //   height: Get.height * 0.5,
              //   width: Get.width,
              //   decoration: const BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [Colors.white, Color.fromRGBO(0, 0, 0, 0)],
              //       // stops: [0.8, 0.85],
              //       begin: Alignment.bottomCenter,
              //       end: Alignment.topCenter,
              //       // tileMode: TileMode.decal,
              //     ),
              //   ),
              // ),
              Positioned(
                top: 10,
                child: Container(
                  width: Get.width,
                  padding: EdgeInsets.only(
                    right: Get.width * 0.2,
                    left: 10,
                    top: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        sloganText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          // fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/logo.png",
                            height: 50,
                            width: 50,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  "ROOMY FINDER",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromRGBO(96, 15, 116, 1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.to(() => const LoginScreen());
                        },
                        child: const Text(
                          "Login in to continue",
                          style: TextStyle(
                            color: Color.fromRGBO(96, 15, 116, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Text('Or'),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.to(() => const RegistrationScreen());
                        },
                        child: const Text(
                          "Register now",
                          style: TextStyle(
                            color: Color.fromRGBO(96, 15, 116, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller._pageIndex.value == 1) {
          return const SizedBox();
        }
        return Container(
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
                OutlinedButton.icon(
                  onPressed: () => changeAppLocale(context),
                  label: Text('language'.tr),
                  icon: const Icon(Icons.language),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
                  ),
                  onPressed: () {
                    controller._pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.linear,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    'letGo'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ));
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

const sloganText = "We connect people who are looking for roommates"
    " and shared accommodation in Dubai";
