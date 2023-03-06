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
        "fcmToken": await FirebaseMessaging.instance.getToken(),
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
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Login"),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                child: Form(
                  key: controller.formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
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
                          Text("rememberMe".tr),
                          Checkbox(
                            value: controller.rememberMe.isTrue,
                            onChanged: controller.isLoading.isTrue
                                ? null
                                : (_) => controller.rememberMe.toggle(),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Get.toNamed('/reset_password'),
                            child: Text('forgotPassword'.tr),
                          )
                        ],
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : controller._login,
                          child: Text("login".tr),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("dontHaveAnAccount".tr),
                          TextButton(
                            onPressed: () =>
                                Get.to(() => const RegistrationScreen()),
                            child: Text('registration'.tr),
                          )
                        ],
                      ),
                    ],
                  ),
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
