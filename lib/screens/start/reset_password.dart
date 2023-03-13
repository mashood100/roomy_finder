import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:pinput/pinput.dart';

class _ResetPasswordScreenController extends LoadingController {
  final _page1Formkey = GlobalKey<FormState>();
  final _page2Formkey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final PageController pageController = PageController();

  final _pageIndex = 0.obs;

  final _showPassword = false.obs;
  final showConfirmPassword = false.obs;

  String _verificationId = "";

  PhoneNumber _phoneNumber = PhoneNumber(dialCode: "+971", isoCode: "AE");

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
    _verificationId = "";
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
          "phone": _phoneNumber.phoneNumber,
          "password": _passwordController.text.trim(),
          "fcmToken": Platform.isIOS
              ? await FirebaseMessaging.instance.getAPNSToken()
              : await FirebaseMessaging.instance.getToken(),
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
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber.phoneNumber,
        verificationCompleted: (credential) async {},
        verificationFailed: (e) {
          Get.log(" Verification failed with code : ${e.code}");

          isLoading(false);
          switch (e.code) {
            case "invalid-phone-number":
              showGetSnackbar(
                "phoneVerificationInvalidPhoneNumber".tr,
                title: 'registration'.tr,
                severity: Severity.error,
              );
              break;
            case "missing-client-identifier":
              showGetSnackbar(
                "phoneVerificationMissingClient".tr,
                title: 'registration'.tr,
                severity: Severity.error,
              );
              break;

            default:
              showGetSnackbar(
                "phoneVerificationCheckInternet".tr,
                title: 'registration'.tr,
                severity: Severity.error,
              );
              break;
          }
        },
        codeSent: (verificationId, forceResendingToken) {
          isLoading(false);
          _verificationId = verificationId;
          moveToCodeVerification();
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: const Duration(minutes: 1),
      );
    } catch (e) {
      isLoading(false);
      showGetSnackbar(
        "phoneVerificationCheckInternet".tr,
        title: 'registration'.tr,
        severity: Severity.error,
      );
    }
  }

  /// Verifies code sents to user and adds the user to **Firebase** if
  /// the code is correct
  Future<void> _signinToFireBaseWithPhone(String smsCode) async {
    isLoading(true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      isLoading(false);
      moveToCredentials();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-verification-code":
          showGetSnackbar(
            "phoneVerificationIncorrectCode".tr,
            title: 'registration'.tr,
            severity: Severity.error,
          );
          break;

        default:
          showGetSnackbar(
            "phoneVerificationPleaseTryAgain".tr,
            title: 'registration'.tr,
            severity: Severity.error,
          );
          break;
      }

      isLoading(false);
      Get.log("$e");
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
                          Text('phoneNumber'.tr),
                          PhoneNumberInput(
                            initialValue: controller._phoneNumber,
                            onChange: (phoneNumber) {
                              controller._phoneNumber = phoneNumber;
                            },
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
                        Text('enterTheVerificationCodeSentTo'.trParams({
                          "phoneNumber":
                              '${controller._phoneNumber.phoneNumber}'
                        })),
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
