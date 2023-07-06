import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/utilities/data.dart';

class _ResetPasswordScreenController extends LoadingController {
  final _page2Formkey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final PageController pageController = PageController();

  final _pageIndex = 0.obs;

  final _showPassword = false.obs;
  final showConfirmPassword = false.obs;

  String _emailVerificationCode = "";
  bool _emailIsVerified = false;
  final _isVerifiyingEmail = false.obs;

  bool get _canVerifyEmail {
    return isLoading.isFalse &&
        _isVerifiyingEmail.isFalse &&
        _emailController.text.isEmail &&
        !_emailIsVerified;
  }

  @override
  void onClose() {
    pageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.onClose();
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

  Future<void> _verifyEmail() async {
    try {
      _isVerifiyingEmail(true);
      update();
      if (_emailVerificationCode.isEmpty) {
        final res = await Dio().post(
          "$API_URL/auth/send-email-verification-code",
          data: {"email": _emailController.text},
        );

        if (res.statusCode == 504) {
          showGetSnackbar(
            "Email service tempprally unavailable. Please try again later",
          );
          return;
        }

        _emailVerificationCode = res.data["code"].toString();
      }
      final userCode = await showInlineInputBottomSheet(
        label: "Code",
        message: "Enter the verification code sent to ${_emailController.text}",
      );

      if (userCode == _emailVerificationCode) {
        _emailIsVerified = true;
        _emailVerificationCode = "";
        update();
      } else {
        showToast("Incorrect code");
        return;
      }
    } catch (e) {
      Get.log("$e");
      showToast("Email verification failed");
    } finally {
      _isVerifiyingEmail(false);
      update();
    }
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

        final res = await ApiService.getDio
            .post('$API_URL/auth/reset-password', data: mapData);

        if (res.statusCode == 500) {
          showGetSnackbar(
            "someThingWentWrong".tr,
            severity: Severity.error,
          );
          isLoading(false);
          return;
        } else if (res.statusCode == 200) {
          await showConfirmDialog(
            "Password reseted successfully".tr,
            isAlert: true,
          );

          Get.back();
        } else if (res.statusCode == 404) {
          showToast("User not found. Please register");

          Get.back();
        } else {
          throw ApiServiceException(statusCode: res.statusCode);
        }
      } catch (e, trace) {
        Get.log("$e");
        Get.log("$trace");
        const message = "Operation failed. Please check your "
            "internet connection and try again";
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.pageController,
                children: [
                  GetBuilder<_ResetPasswordScreenController>(
                      builder: (controller) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          InlineTextField(
                            labelText: 'email'.tr,
                            hintText: 'emailAddress'.tr,
                            enabled: controller.isLoading.isFalse &&
                                !controller._emailIsVerified,
                            onChanged: (value) {
                              controller._emailVerificationCode = "";
                              controller.update();
                            },
                            controller: controller._emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'thisFieldIsRequired'.tr;
                              }
                              if (!value.isEmail) {
                                return 'invalidEmail'.tr;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Builder(builder: (context) {
                            final color = controller._emailIsVerified
                                ? Colors.green
                                : !controller._canVerifyEmail
                                    ? Colors.grey
                                    : ROOMY_ORANGE;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(color: color),
                                ),
                                onPressed: !controller._canVerifyEmail
                                    ? null
                                    : controller._verifyEmail,
                                child: controller._isVerifiyingEmail.isTrue
                                    ? const CupertinoActivityIndicator()
                                    : Text(
                                        controller._emailIsVerified
                                            ? "Verified"
                                            : "Verify",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          Builder(builder: (context) {
                            if (!controller._emailIsVerified) {
                              return const SizedBox();
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ROOMY_ORANGE,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: ROOMY_ORANGE),
                                ),
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : controller.moveToCredentials,
                                child: const Text(
                                  "Next",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
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
                    );
                  }),
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Form(
                        key: controller._page2Formkey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            InlineTextField(
                              labelText: 'New password',
                              obscureText: controller._showPassword.isFalse,
                              controller: controller._passwordController,
                              hintText: 'Enter new password',
                              suffixIcon: IconButton(
                                onPressed: controller._showPassword.toggle,
                                icon: controller._showPassword.isTrue
                                    ? const Icon(CupertinoIcons.eye_slash_fill)
                                    : const Icon(CupertinoIcons.eye_fill),
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
                            const SizedBox(height: 20),
                            InlineTextField(
                              labelText: 'Confirm password',
                              obscureText:
                                  controller.showConfirmPassword.isFalse,
                              controller: controller._confirmPasswordController,
                              hintText: "Confirm your password",
                              suffixIcon: IconButton(
                                onPressed:
                                    controller.showConfirmPassword.toggle,
                                icon: controller.showConfirmPassword.isTrue
                                    ? const Icon(CupertinoIcons.eye_slash_fill)
                                    : const Icon(CupertinoIcons.eye_fill),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ROOMY_ORANGE,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: ROOMY_ORANGE),
                                ),
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : controller._resetPasword,
                                child: Text(
                                  "finish".tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    });
  }
}
