import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:pinput/pinput.dart';

class _ResetPasswordScreenController extends LoadingController {
  final _page1Formkey = GlobalKey<FormState>();
  final _page2Formkey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final PageController pageController = PageController();

  final _pageIndex = 0.obs;

  final _showPassword = false.obs;
  final showConfirmPassword = false.obs;

  String _code = "";

  @override
  void onClose() {
    pageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.onClose();
  }

  void moveToPhoneNumberInput() {
    pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _pageIndex(0);
    _code = "";
  }

  void moveToCodeVerification() {
    pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _pageIndex(1);
  }

  void moveToCredentials() {
    pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _pageIndex(2);
  }

  Future<void> _resetPasword() async {
    if (_page2Formkey.currentState!.validate()) {
      try {
        isLoading(true);

        final mapData = {
          "email": _emailController.text,
          "password": _passwordController.text.trim(),
          "fcmToken": await FirebaseMessaging.instance.getToken(),
        };

        final res =
            await Dio().post('$API_URL/auth/reset-password', data: mapData);

        if (res.statusCode == 500) {
          showGetSnackbar(
            "someThingWentWrong".tr,
            severity: Severity.error,
          );
          isLoading(false);
          return;
        }

        if (res.statusCode == 200) {
          isLoading(false);

          await showConfirmDialog(
            "Password reseted successfully".tr,
            isAlert: true,
          );

          Get.back();
        } else {
          throw ApiServiceException(statusCode: res.statusCode);
        }
      } catch (e, trace) {
        Get.log("$e");
        Get.log("$trace");
        final message =
            "operationFailed".tr + "checkInternetConnectionAndTryAgain".tr;
        showGetSnackbar(
          message,
          title: "registration".tr,
          severity: Severity.error,
        );
      } finally {
        isLoading(false);
      }
    }
  }

  Future<void> _getVerificationCode() async {
    if (!_page1Formkey.currentState!.validate()) return;

    isLoading(true);

    try {
      final res = await Dio().get(
        '$API_URL/auth/reset-password',
        queryParameters: {"email": _emailController.text},
      );

      if (res.statusCode == 200) {
        _code = res.data["code"];
        moveToCodeVerification();
      } else {
        showToast("Something went wrong");
      }
    } catch (e) {
      isLoading(false);
      showGetSnackbar(
        "phoneVerificationCheckInternet".tr,
        title: 'registration'.tr,
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
  }

  /// Verifies code sents to user and adds the user to **Firebase** if
  /// the code is correct
  Future<void> _signinToFireBaseWithPhone(String smsCode) async {
    isLoading(true);

    try {
      if (_code.isNotEmpty) {
        return;
      }
      if (smsCode != _code) {
        showToast("Incorrect code");
        return;
      }

      isLoading(false);
      moveToCredentials();
    } catch (e) {
      showGetSnackbar(
        "phoneVerificationPleaseTryAgain".tr,
        title: 'registration'.tr,
        severity: Severity.error,
      );
      isLoading(false);
      Get.log("$e");
    }
  }
}

class ResetPasswordScreen extends GetView<_ResetPasswordScreenController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ResetPasswordScreenController());
    return Obx(() {
      return Scaffold(
        appBar: AppBar(title: Text("resetPassword".tr)),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.pageController,
                children: [
                  SingleChildScrollView(
                    child: Form(
                      key: controller._page1Formkey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          InlineTextField(
                            labelText: "email".tr,
                            hintText: "emailAddress".tr,
                            controller: controller._emailController,
                            suffixIcon: const Icon(CupertinoIcons.mail),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'thisFieldIsRequired'.tr;
                              }

                              if (!value.isEmail) return 'invalidEmail'.tr;

                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("alreadyHaveAnAccount".tr),
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text('login'.tr),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Enter the verification code sent '
                          'to ${controller._emailController.text}',
                        ),
                        const SizedBox(height: 10),
                        Pinput(
                          length: 6,
                          enabled: !controller.isLoading.isTrue,
                          onCompleted: controller._signinToFireBaseWithPhone,
                          defaultPinTheme: PinTheme(
                            height: 40,
                            width: 35,
                            textStyle: const TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 56, 94, 128),
                                fontWeight: FontWeight.w600),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromRGBO(234, 239, 243, 1),
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text('didNotReicievedCode'.tr),
                        TextButton(
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : controller.moveToPhoneNumberInput,
                          child: Text('resend'.tr),
                        )
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Form(
                        key: controller._page2Formkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New password'.tr),
                            TextFormField(
                              obscureText: controller._showPassword.isFalse,
                              controller: controller._passwordController,
                              decoration: InputDecoration(
                                hintText: 'Enter new password',
                                suffixIcon: IconButton(
                                  onPressed: controller._showPassword.toggle,
                                  icon: controller._showPassword.isTrue
                                      ? const Icon(
                                          CupertinoIcons.eye_slash_fill)
                                      : const Icon(CupertinoIcons.eye_fill),
                                ),
                              ),
                              validator: (value) {
                                if (value == null) {
                                  return 'thisFieldIsRequired'.tr;
                                }
                                if (value.isEmpty) {
                                  return 'thisFieldIsRequired'.tr;
                                }
                                if (value.length < 7 || value.length > 15) {
                                  return 'passwordLengthMessage'.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Text('Confirm password'.tr),
                            TextFormField(
                              obscureText:
                                  controller.showConfirmPassword.isFalse,
                              controller: controller._confirmPasswordController,
                              decoration: InputDecoration(
                                hintText: "Confirm your password",
                                suffixIcon: IconButton(
                                  onPressed:
                                      controller.showConfirmPassword.toggle,
                                  icon: controller.showConfirmPassword.isTrue
                                      ? const Icon(
                                          CupertinoIcons.eye_slash_fill)
                                      : const Icon(CupertinoIcons.eye_fill),
                                ),
                              ),
                              validator: (value) {
                                if (value !=
                                    controller._passwordController.text) {
                                  return 'passwordDontMatch'.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : controller._resetPasword,
                                child: Text("finish".tr),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isLoading.isTrue) const LinearProgressIndicator(),
          ],
        ),
        floatingActionButton: Obx(
          () {
            if (controller._pageIndex.value == 0) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.isTrue
                      ? null
                      : controller._getVerificationCode,
                  child: Text("getVerificationCode".tr),
                ),
              );
            }
            return Container();
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    });
  }
}
