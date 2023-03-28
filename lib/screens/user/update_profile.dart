import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';

class _UpdateProfileController extends LoadingController {
  final _formkeyCredentials = GlobalKey<FormState>();

  final showPassword = false.obs;
  final showConfirmPassword = false.obs;

  String _emailVerificationCode = "";
  bool _emailIsVerified = false;

  // Information
  final accountType = UserAccountType.landlord.obs;
  final information = <String, String>{
    "gender": "Male",
    "email": "",
    "firstName": "",
    "lastName": "",
    "country": allCountriesNames[0],
  };

  bool get _canVerifyEmail {
    return isLoading.isFalse &&
        AppController.me.email != information["email"] &&
        "${information["email"]}".isEmail &&
        !_emailIsVerified;
  }

  @override
  void onInit() {
    information["gender"] = AppController.me.gender;
    information["email"] = AppController.me.email;
    information["firstName"] = AppController.me.firstName;
    information["lastName"] = AppController.me.lastName;
    information["country"] = AppController.me.country;
    super.onInit();
  }

  Future<void> _verifyEmail() async {
    try {
      if (_emailVerificationCode.isEmpty) {
        final codeRes = await ApiService.getDio.post(
          "/auth/send-email-verification-code",
          queryParameters: {"email": information['email']},
        );

        await Future.delayed(const Duration(seconds: 5));

        _emailVerificationCode = codeRes.data["code"];
      }

      final userCode = await showInlineInputBottomSheet(
        label: "Code",
        message: "Enter the verification code sent to ${information['email']}",
      );

      if (userCode == _emailVerificationCode) {
        _emailIsVerified = true;
        update();
      } else {
        showToast("Incorrect code");
        return;
      }
    } catch (e) {
      showToast("Email verification failed");
    }
  }

  Future<void> _saveCredentials() async {
    if (_canVerifyEmail) {
      if (!_emailIsVerified) {
        showToast("Please verify email");
        return;
      }
    }
    try {
      isLoading(true);

      final res = await ApiService.getDio.put(
        "/auth/credentials",
        data: information,
      );

      if (res.statusCode == 200) {
        AppController.instance.user.update((val) {
          if (val == null) return;

          val.gender = information["gender"] as String;
          val.email = information["email"] as String;
          val.firstName = information["firstName"] as String;
          val.lastName = information["lastName"] as String;
          val.country = information["country"] as String;
        });

        showToast("Info updated successlly");
        _emailVerificationCode = "";
      } else {
        showToast("Update failed");
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar("somethingWentWrong".tr);
    } finally {
      isLoading(false);
    }
  }
}

class UpdateUserProfile extends StatelessWidget {
  const UpdateUserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_UpdateProfileController());

    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Update profile"),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: SingleChildScrollView(
                child: Form(
                  key: controller._formkeyCredentials,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // information
                      const SizedBox(height: 10),
                      InlineDropdown<String>(
                        labelText: 'Gender'.tr,
                        value: controller.information["gender"] as String,
                        items: const ["Male", "Female"],
                        onChanged: controller.isLoading.isTrue
                            ? null
                            : (val) {
                                if (val != null) {
                                  controller.information["gender"] = val;
                                }
                              },
                      ),
                      const SizedBox(height: 10),
                      InlineTextField(
                        initialValue: controller.information["email"],
                        labelText: 'emailAddress'.tr,
                        suffixIcon: IconButton(
                          onPressed: controller._canVerifyEmail
                              ? null
                              : () {
                                  controller._verifyEmail();
                                },
                          icon: const Icon(CupertinoIcons.mail),
                        ),
                        enabled: controller.isLoading.isFalse &&
                            !controller._emailIsVerified,
                        onChanged: (value) =>
                            controller.information["email"] = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'thisFieldIsRequired'.tr;
                          }
                          if (!value.isEmail) return 'invalidEmail'.tr;
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      InlineTextField(
                        initialValue: controller.information["firstName"],
                        enabled: controller.isLoading.isFalse,
                        labelText: 'firstName'.tr,
                        suffixIcon: const Icon(CupertinoIcons.person),
                        onChanged: (value) =>
                            controller.information["firstName"] = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'thisFieldIsRequired'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      InlineTextField(
                        labelText: "lastName".tr,
                        initialValue: controller.information["lastName"],
                        enabled: controller.isLoading.isFalse,
                        suffixIcon: const Icon(CupertinoIcons.person),
                        onChanged: (value) =>
                            controller.information["lastName"] = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'thisFieldIsRequired'.tr;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),
                      InlineDropdown<String>(
                        labelText: 'country'.tr,
                        value: controller.information["country"],
                        items: allCountriesNames,
                        onChanged: controller.isLoading.isTrue
                            ? null
                            : (val) {
                                if (val != null) {
                                  controller.information["country"] = val;
                                }
                              },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            controller._saveCredentials();
                          },
                          child: const Text("Save"),
                        ),
                      )
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }
}
