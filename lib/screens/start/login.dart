import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/start/registration.dart';

class _LoginController extends LoadingController {
  final formkey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final country = Country.currentCountry.obs;

  final rememberMe = false.obs;

  final showPassword = false.obs;

  Future<void> _login() async {
    if (!formkey.currentState!.validate()) return;
    try {
      isLoading(true);
      final dio = ApiService.getDio;

      final data = {
        'email': _emailController.text,
        "password": _passwordController.text,
        "fcmToken": Platform.isIOS
            ? await FirebaseMessaging.instance.getAPNSToken()
            : await FirebaseMessaging.instance.getToken(),
      };

      final res = await dio.post("/auth/login", data: data);

      switch (res.statusCode) {
        case 200:
          final user = User.fromMap(res.data);

          AppController.instance.user = user.obs;
          AppController.instance.userPassword = _passwordController.text;

          AppNotication.currentUser = user;

          if (rememberMe.isTrue) {
            await AppController.instance.saveUser();
            await AppController.instance
                .saveUserPassword(_passwordController.text);
          }

          AppController.instance.setIsFirstStart(false);

          Get.offAllNamed("/home");
          break;
        case 403:
          if (res.data["code"] == "diabled") {
            showGetSnackbar(
              "Account disabled. Please contactact the support team".tr,
              severity: Severity.error,
            );
          } else {
            showGetSnackbar(
              "Incorrect credentials".tr,
              severity: Severity.error,
            );
          }

          break;
        case 404:
          showGetSnackbar(
            "incorrectCredentials".tr,
            severity: Severity.error,
          );

          break;
        case 500:
          showGetSnackbar(
            "someThingWentWrong".tr,
            severity: Severity.error,
          );
          break;
        default:
          throw ApiServiceException(statusCode: res.statusCode);
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar(
        ("Failed to login. Please check your internet connection and try again"
            .tr),
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    _passwordController.dispose();
    super.onClose();
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_LoginController());
    return Obx(() {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Form(
                key: controller.formkey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                        bottom: 25,
                        left: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Get.theme.appBarTheme.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              BackButton(color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Welcome Back!",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Please sign in to continue",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('email'.tr),
                          TextFormField(
                            controller: controller._emailController,
                            decoration: InputDecoration(
                              suffixIcon: const Icon(CupertinoIcons.mail),
                              hintText: "emailAddress".tr,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'thisFieldIsRequired'.tr;
                              }

                              if (!value.isEmail) return 'invalidEmail'.tr;

                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          Text('password'.tr),
                          TextFormField(
                            obscureText: controller.showPassword.isFalse,
                            controller: controller._passwordController,
                            decoration: InputDecoration(
                              hintText: "enterYourPassword".tr,
                              suffixIcon: IconButton(
                                onPressed: controller.showPassword.toggle,
                                icon: controller.showPassword.isTrue
                                    ? const Icon(CupertinoIcons.eye_slash_fill)
                                    : const Icon(CupertinoIcons.eye_fill),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'thisFieldIsRequired'.tr;
                              }

                              return null;
                            },
                            keyboardType: TextInputType.visiblePassword,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                child: Checkbox(
                                  value: controller.rememberMe.isTrue,
                                  onChanged: controller.isLoading.isTrue
                                      ? null
                                      : (_) => controller.rememberMe.toggle(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text("rememberMe".tr),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Get.toNamed('/reset_password'),
                                child: Text('forgotPassword'.tr),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .appBarTheme
                                    .backgroundColor,
                              ),
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : controller._login,
                              child: Text(
                                "Sign in".tr,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(child: Text("dontHaveAnAccount".tr)),
                              TextButton(
                                onPressed: () =>
                                    Get.off(() => const RegistrationScreen()),
                                child: Text(
                                  'Register now'.tr,
                                  style: TextStyle(
                                    color:
                                        Get.theme.appBarTheme.backgroundColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            if (controller.isLoading.isTrue)
              const LinearProgressIndicator(
                color: Color.fromRGBO(96, 15, 116, 1),
              ),
          ],
        ),
      );
    });
  }
}
