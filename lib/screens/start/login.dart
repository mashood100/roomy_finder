import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/user/user.dart';
import 'package:roomy_finder/screens/home/home_tab.dart';
import 'package:roomy_finder/screens/start/registration.dart';
import 'package:roomy_finder/utilities/data.dart';

class _LoginController extends LoadingController {
  final formkey = GlobalKey<FormState>();
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  final country = Country.currentCountry.obs;
  final data = {"email": "", "password": ""};

  final showPassword = false.obs;
  final savePassword = false.obs;

  Future<void> _login() async {
    if (!formkey.currentState!.validate()) return;

    try {
      isLoading(true);
      final dio = ApiService.getDio;

      final map = {
        'email': data["email"],
        "password": data["password"],
        "fcmToken": await FirebaseMessaging.instance.getToken(),
      };

      final res = await dio.post("/auth/login", data: map);

      switch (res.statusCode) {
        case 200:
          final user = User.fromMap(res.data);

          AppController.instance.user = user.obs;
          AppController.instance.userPassword = data["password"];
          AppController.setupFCMTokenHandler();

          await AppController.saveUser(user);
          await AppController.saveUserPassword(data["password"]!);

          AppController.instance.setIsFirstStart(false);

          if (FirebaseAuth.instance.currentUser != null) {
            await FirebaseAuth.instance
                .signInWithCustomToken(res.data["firebaseToken"]);
          }

          if (user.isMaintenant) {
            showToast("Maintenance accounts are temporally unavailable");
          } else {
            Get.offAllNamed("/home");
          }

          ApiService.setLanlordIsBlocked();

          break;
        case 403:
          if (res.data["code"] == "diabled") {
            showGetSnackbar(
              "Account disabled. Please contactact the support team".tr,
              severity: Severity.error,
            );
          } else if (res.data["code"] == "use-third-party") {
            showGetSnackbar(
              res.data["message"] ??
                  "You signed up with a provider. Please login with this provider",
              severity: Severity.info,
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
            "Account not found. Please sign up",
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
        ("Failed to login. Please check your internet connection and try again"),
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
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
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Stack(
            children: [
              const BackButton(),
              Form(
                key: controller.formkey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(flex: 2),
                    if (MediaQuery.of(context).viewInsets.bottom < 20)
                      Expanded(
                        flex: 3,
                        child: Hero(
                          tag: "logo",
                          child: Image.asset("assets/images/logo.png"),
                        ),
                      ),
                    const Spacer(flex: 1),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        color: ROOMY_PURPLE,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.elliptical(50, 40),
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // const Text("Email"),
                              // const SizedBox(height: 5),
                              InlineTextField(
                                hintText: "emailAddress".tr,
                                suffixIcon: const Icon(CupertinoIcons.mail),
                                initialValue: controller.data["email"],
                                onChanged: (value) {
                                  controller.data["email"] = value;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }

                                  if (!value.isEmail) return 'invalidEmail'.tr;

                                  return null;
                                },
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                fillColor: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              // const Text("Password"),
                              // const SizedBox(height: 5),
                              InlineTextField(
                                hintText: "enterYourPassword".tr,
                                obscureText: controller.showPassword.isFalse,
                                initialValue: controller.data["password"],
                                onChanged: (value) {
                                  controller.data["password"] = value;
                                },
                                suffixIcon: IconButton(
                                  onPressed: controller.showPassword.toggle,
                                  icon: controller.showPassword.isTrue
                                      ? const Icon(
                                          CupertinoIcons.eye_slash_fill)
                                      : const Icon(CupertinoIcons.eye_fill),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }

                                  return null;
                                },
                                keyboardType: TextInputType.visiblePassword,
                                fillColor: Colors.white,
                              ),
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
                                  onPressed: controller.isLoading.isTrue
                                      ? null
                                      : controller._login,
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

                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    child: Checkbox(
                                      value: controller.savePassword.value,
                                      onChanged: controller.savePassword,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: ROOMY_ORANGE,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () =>
                                        Get.toNamed('/reset_password'),
                                    child: Text(
                                      'forgotPassword'.tr,
                                      style: const TextStyle(
                                        color: ROOMY_ORANGE,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () => Get.off(
                                        () => const RegistrationScreen()),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.to(() => const HomeTab());
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
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (controller.isLoading.isTrue)
                Container(
                  alignment: Alignment.center,
                  color: Colors.grey.withOpacity(0.3),
                  child: CircularProgressIndicator(
                    color: Colors.grey.withOpacity(0.8),
                    strokeWidth: 2,
                  ),
                )
            ],
          ),
        ),
      );
    });
  }
}
