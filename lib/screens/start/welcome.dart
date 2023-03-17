import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                  padding: const EdgeInsets.all(20),
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
                        // textAlign : TextAlign.center,
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
                                // width: 100,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "ROOMY ",
                                        style: TextStyle(
                                          color:
                                              Color.fromRGBO(255, 123, 77, 1),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "FINDER",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: 22,
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
                          "Login to continue",
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
    );
  }
}

const sloganText = "We connect people who are looking for roommates"
    " and shared accommodation in Dubai";
