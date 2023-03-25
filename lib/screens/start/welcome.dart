import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/start/registration.dart';
import 'package:roomy_finder/utilities/data.dart';

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
      appBar: AppBar(toolbarHeight: 0),
      body: Stack(
        children: [
          // Image.asset(
          //   "assets/images/dubai-city.jpg",
          //   width: Get.width,
          //   height: Get.height,
          //   fit: BoxFit.cover,
          //   alignment: Alignment.topCenter,
          // ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  "assets/images/logo.png",
                  height: 100,
                  width: 100,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Roomy ",
                style: TextStyle(
                  color: ROOMY_PURPLE,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Text(
                "FINDER ",
                style: TextStyle(
                  color: ROOMY_ORANGE,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              const Spacer(),
              const Text(
                "Welcome ",
                style: TextStyle(
                  color: ROOMY_PURPLE,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                decoration: const BoxDecoration(
                  color: ROOMY_PURPLE,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: ROOMY_ORANGE,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(color: ROOMY_ORANGE),
                        ),
                        onPressed: () {
                          Get.to(() => const LoginScreen());
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.to(() => const RegistrationScreen());
                        },
                        style: OutlinedButton.styleFrom(
                          // backgroundColor: ROOMY_ORANGE,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(color: ROOMY_ORANGE),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: ROOMY_ORANGE,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Get.offAllNamed("/home");
                        },
                        style: TextButton.styleFrom(
                          // backgroundColor: ROOMY_ORANGE,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.white,
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
