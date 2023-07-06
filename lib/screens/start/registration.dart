import 'dart:async';

import 'dart:io';

import "package:path/path.dart" as path;
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pinput/pinput.dart';
import 'package:roomy_finder/functions/third_parties_providers.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/utility_screens/view_pdf.dart';
import 'package:roomy_finder/utilities/data.dart';

class _RegistrationController extends LoadingController {
  final _formkeyCredentials = GlobalKey<FormState>();

  final _isVerifiyingEmail = false.obs;

  late final PageController _pageController;
  final _piniputController = TextEditingController();
  final _pageIndex = 0.obs;

  final showPassword = false.obs;
  final showConfirmPassword = false.obs;
  final acceptTermsAndConditions = false.obs;
  final acceptLandlordPolicy = false.obs;
  PhoneNumber phoneNumber = PhoneNumber(dialCode: "971", isoCode: "AE");

  String _emailVerificationCode = "";
  bool _emailIsVerified = false;

  bool get isLandlord => accountType.value == UserAccountType.landlord;
  bool get isRoommate => accountType.value == UserAccountType.roommate;
  bool get isMaintenant => accountType.value == UserAccountType.maintainer;

  // Information
  final accountType = UserAccountType.none.obs;
  final _images = <CroppedFile>[].obs;
  final information = <String, String>{
    "email": "",
    "firstName": "",
    "lastName": "",
    "password": "",
    "confirmPassword": "",
  };

  Timer? secondsLeftTimer;

  final secondsLeft = 59.obs;

  bool get _canVerifyEmail {
    return isLoading.isFalse &&
        _isVerifiyingEmail.isFalse &&
        "${information["email"]}".isEmail &&
        !_emailIsVerified;
  }

  Future<String> get _formattedPhoneNumber async {
    try {
      final data = await PhoneNumber.getParsableNumber(phoneNumber);
      return "(${phoneNumber.dialCode}) $data";
    } on Exception catch (_) {
      return phoneNumber.phoneNumber ?? "";
    }
  }

  @override
  void onInit() {
    _pageController = PageController();
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _piniputController.dispose();
    super.onClose();
  }

  void startSmsTimer() {
    secondsLeftTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value == 0) {
        timer.cancel();
      } else {
        secondsLeft(secondsLeft.value - 1);
      }
    });
  }

  void resetSmsTimer() {
    secondsLeftTimer?.cancel();
    secondsLeft(59 * 5);
  }

  Future<void> _verifyEmail() async {
    try {
      _isVerifiyingEmail(true);
      update();

      if (_emailVerificationCode.isEmpty) {
        final res = await ApiService.getDio.post(
          "/auth/send-email-verification-code",
          data: {"email": information['email']},
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
        message: "Enter the verification code sent to ${information['email']}",
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

  Future<void> sendSmsCode() async {
    try {
      isLoading(true);
      resetSmsTimer();
      secondsLeft(59 * 10);
      _piniputController.clear();

      final res = await ApiService.getDio.post(
        "/auth/send-otp-code",
        data: {"phone": phoneNumber.phoneNumber},
      );

      if (res.statusCode == 200) {
        _moveToPage(2);
        startSmsTimer();
      } else {
        showToast("Failed to get OTP code. Please try again.");
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
    } finally {
      isLoading(false);
    }
  }

  void _moveToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void _moveToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void _viewPropfilePicture() {
    if (_images.isEmpty) return;

    showModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Image.file(File(_images[0].path)),
        );
      },
    );
  }

  Future<void> _saveCredentials(String otpCode) async {
    try {
      isLoading(true);

      // await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //   email: information['email']!,
      //   password: information['password']!,
      // );

      // await FirebaseAuth.instance.signInAnonymously();

      String? imageUrl;

      if (_images.isNotEmpty) {
        final imgRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child("propile-pictures")
            .child(
                '/${createDateTimeFileName()}${path.extension(_images[0].path)}');

        final uploadTask =
            imgRef.putData(await File(_images[0].path).readAsBytes());

        imageUrl = await (await uploadTask).ref.getDownloadURL();
      }

      final data = {
        ...information,
        "type": accountType.value.name,
        "phone": phoneNumber.phoneNumber,
        "fcmToken": await FirebaseMessaging.instance.getToken(),
        "profilePicture": imageUrl,
        "otpCode": otpCode,
      };

      data.remove("confirmPassword");

      final res = await ApiService.getDio.post("/auth/credentials", data: data);

      if (res.statusCode == 403) {
        showToast(res.data["message"] ?? "Incorrect OTP code");
        return;
      } else if (res.statusCode == 409) {
        showGetSnackbar(
          "thisUserAlreadyExistPleaseLogin".tr,
          title: "registration".tr,
          severity: Severity.warning,
          action: SnackBarAction(
            label: 'login'.tr,
            onPressed: () => Get.offAndToNamed("/login"),
          ),
        );
        return;
      } else if (res.statusCode == 500) {
        showGetSnackbar(
          "someThingWentWrong".tr,
          severity: Severity.error,
        );
        return;
      } else if (res.statusCode == 201) {
        final User user = User.fromMap(res.data);

        AppController.instance.user = user.obs;
        AppController.instance.setIsFirstStart(false);
        AppController.instance.userPassword = information["password"];
        AppController.setupFCMTokenHandler();

        await FirebaseAuth.instance
            .signInWithCustomToken(res.data["firebaseToken"]);

        if (user.isMaintenant) {
          Get.offAllNamed("/maintenance");
          FirebaseMessaging.instance.subscribeToTopic("maintenance-broadcast");
        } else {
          Get.offAllNamed("/home");
        }
      } else {
        throw ApiServiceException(statusCode: res.statusCode);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          showToast("This email is already used");
          break;

        case "invalid-email":
          showToast("This email is invalid");
          break;

        case "weak-password":
          showToast("Password too weak. Please use strong password");
          break;

        default:
          showGetSnackbar(
            "operationFailedTheCodeMayHaveExpiredResentTheCode".tr,
            title: 'registration'.tr,
            severity: Severity.error,
          );
      }

      Get.log("$e");
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar("somethingWentWrong".tr, severity: Severity.error);
    } finally {
      isLoading(false);
    }
  }

  Future<bool> _validateCredentials() async {
    try {
      if (_formkeyCredentials.currentState?.validate() != true) return false;

      if (acceptTermsAndConditions.isFalse) {
        showToast("Please accept terms and conditions");
        return false;
      }
      if (acceptLandlordPolicy.isFalse && isLandlord) {
        showToast("Please accept landlord policies");
        return false;
      }
      if (_canVerifyEmail) {
        if (!_emailIsVerified) {
          showToast("Please verify email");
          return false;
        }
      }
      isLoading(true);

      // final exist = await ApiService.checkIfUserExist(information["email"]!);

      // if (exist) {
      //   showGetSnackbar(
      //     "This email address already have an account. Please login instead".tr,
      //     title: "registration".tr,
      //     severity: Severity.warning,
      //   );
      //   isLoading(false);
      //   return false;
      // }

      return true;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> _validateFisrtPage() async {
    if (!_emailIsVerified) {
      showToast("Please verify email");
      return false;
    }

    if (accountType.value == UserAccountType.none) {
      showToast("Please choose an account type");
      return false;
    }
    if (acceptTermsAndConditions.isFalse) {
      showToast("Please read and accept terms & conditions");
      return false;
    }
    if (acceptLandlordPolicy.isFalse && isLandlord) {
      showToast("Please read and accept landlord policies");
      return false;
    }

    try {
      isLoading(true);

      final exist = await ApiService.checkIfUserExist(information["email"]!);

      if (exist) {
        showGetSnackbar(
          "This email address already have an account. Please login instead".tr,
          title: "registration".tr,
          severity: Severity.warning,
        );
        return false;
      }
    } catch (e) {
      showToast("Validation failed. Please check your connexion and try again");
      Get.log("$e");
    } finally {
      isLoading(false);
    }

    return true;
  }

  Future<void> _pickProfilePicture({bool gallery = true}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image;

      if (gallery) {
        image = await picker.pickImage(source: ImageSource.gallery);
      } else {
        image = await picker.pickImage(source: ImageSource.camera);
      }

      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'profilePicture'.tr,
              toolbarColor: Colors.purple,
              toolbarWidgetColor: Get.theme.colorScheme.background,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'profilePicture'.tr,
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          _images.clear();
          _images.add(croppedFile);
        }
      }
    } catch (e) {
      Get.log("$e");
      showGetSnackbar(
        'errorPickingProfilePicture'.tr,
        title: 'credentials'.tr,
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _registerWithProvider(String provider) async {
    try {
      if (accountType.value == UserAccountType.none) {
        showToast("Please choose an account type");
        return;
      }

      if (acceptTermsAndConditions.isFalse) {
        showToast("Please read and accept terms & conditions");
        return;
      }
      if (acceptLandlordPolicy.isFalse && isLandlord) {
        showToast("Please read and accept landlord policies");
        return;
      }
      isLoading(true);

      final UserCredential cred;

      switch (provider) {
        case "google.com":
          cred = await ThirdPartyProvider.signInWithGoogle(true);

          break;
        case "apple.com":
          cred = await ThirdPartyProvider.signInWithApple(true);

          break;
        // case "facebook.com":
        //   cred = await ThirdPartyProvider.signInWithFacebook(true);

        //   break;
        default:
          return;
      }

      final user = cred.user;

      if (user != null) {
        if (user.email == null) {
          var message = "Can't sign up with this provider."
              " Email address isn't available.";

          showToast(message);
          return;
        }

        var fullName = user.displayName!;

        String firstName = fullName.split(" ")[0];
        String lastName = "N/A";

        if (fullName.split(" ").length > 1) lastName = fullName.split(" ")[1];

        final data = {
          "type": accountType.value.name,
          "email": user.email!,
          "phone": user.phoneNumber,
          "firstName": firstName,
          "lastName": lastName,
          "profilePicture": user.photoURL,
          "fcmToken": await FirebaseMessaging.instance.getToken(),
          "userToken": await user.getIdToken(),
          "authProvider": provider,
        };
        // print(data);
        final res = await ApiService.getDio.post(
          "/auth/registration-third-party",
          data: data,
        );

        if (res.statusCode == 403) {
          showToast(res.data["message"] ?? "Unauthorised registration");
          return;
        } else if (res.statusCode == 409) {
          showGetSnackbar(
            res.data["message"] ?? "This user already exist. Please login",
            title: "registration".tr,
            severity: Severity.warning,
          );
          return;
        } else if (res.statusCode == 500) {
          showToast("Something went wrong. Please try again later".tr);
          return;
        } else if (res.statusCode == 201) {
          final User user = User.fromMap(res.data);

          AppController.instance.user = user.obs;
          AppController.instance.setIsFirstStart(false);
          AppController.instance.userPassword = res.data["password"];
          AppController.setupFCMTokenHandler();

          if (user.isMaintenant) {
            Get.offAllNamed("/maintenance");
            FirebaseMessaging.instance
                .subscribeToTopic("maintenance-broadcast");
          } else {
            Get.offAllNamed("/home");
          }
        } else {
          showToast("Operation failed with status code ${res.statusCode}".tr);
        }
      } else {
        showToast("Failed to sign up with provider. User not found".tr);
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showToast("Failed to sign up with provider");
    } finally {
      isLoading(false);
    }
  }
}

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_RegistrationController());

    return WillPopScope(
      onWillPop: () async {
        if (controller._pageIndex.value != 0) {
          controller._moveToPreviousPage();
          return false;
        }
        return true;
      },
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Registration"),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Stack(
              children: [
                Container(
                  height: 15,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Get.theme.appBarTheme.backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.elliptical(50, 25),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10, top: 30, right: 10, bottom: 60),
                  child: PageView(
                    controller: controller._pageController,
                    onPageChanged: (index) => controller._pageIndex(index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            // Choose Account type
                            const Text("Please choose your account type"),
                            const SizedBox(height: 20),
                            // Account type
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                (
                                  label: "Roommate",
                                  value: UserAccountType.roommate
                                ),
                                (
                                  label: "Landlord",
                                  value: UserAccountType.landlord
                                ),
                                // (
                                //   label: "Maintenant",
                                //   value: UserAccountType.maintainer
                                // ),
                              ].map((e) {
                                return GestureDetector(
                                  onTap: controller.isLoading.isTrue
                                      ? null
                                      : () {
                                          controller.accountType(e.value);
                                        },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        controller.accountType.value == e.value
                                            ? Icons
                                                .check_circle_outline_outlined
                                            : Icons.circle_outlined,
                                        color: ROOMY_ORANGE,
                                      ),
                                      Text(
                                        e.label,
                                        style: const TextStyle(
                                          color: ROOMY_PURPLE,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 50),

                            Row(
                              children: [
                                Expanded(
                                  child: InlineTextField(
                                    labelWidth: 0,
                                    // labelText: 'email'.tr,
                                    hintText: "Enter your email address",
                                    initialValue:
                                        controller.information["email"],
                                    enabled: controller.isLoading.isFalse &&
                                        !controller._emailIsVerified,
                                    onChanged: (value) {
                                      controller.information["email"] =
                                          value.toLowerCase();
                                      controller._emailVerificationCode = "";
                                      controller.update();
                                    },
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
                                ),
                                const SizedBox(width: 5),
                                GetBuilder<_RegistrationController>(
                                    builder: (controller) {
                                  final color = controller._emailIsVerified
                                      ? Colors.green
                                      : !controller._canVerifyEmail
                                          ? Colors.grey
                                          : ROOMY_ORANGE;
                                  return ElevatedButton(
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
                                  );
                                })
                              ],
                            ),

                            const SizedBox(height: 30),

                            const Row(children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("Or sign up with"),
                              ),
                              Expanded(child: Divider()),
                            ]),

                            const SizedBox(height: 30),

                            // Third parties
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                (
                                  label: "Google",
                                  asset: "assets/images/social/google.png",
                                  onTap: controller.isLoading.isTrue
                                      ? null
                                      : () => controller
                                          ._registerWithProvider("google.com"),
                                ),
                                (
                                  label: "Apple",
                                  asset: "assets/images/social/apple.png",
                                  onTap: controller.isLoading.isTrue
                                      ? null
                                      : () => controller
                                          ._registerWithProvider("apple.com"),
                                ),
                                // (
                                //   label: "Facebook",
                                //   asset: "assets/images/social/facebook.png",
                                //   onTap: controller.isLoading.isTrue
                                //       ? null
                                //       : () => controller._registerWithProvider(
                                //           "facebook.com"),
                                // )
                              ].map((e) {
                                return GestureDetector(
                                  onTap: e.onTap,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        e.asset,
                                        height: 40,
                                        width: 40,
                                      ),
                                      // Text(e.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 30),
                            // Agreements
                            Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  (
                                    label: "Terms & Conditions",
                                    pdf: "assets/pdf/terms-and-conditions.pdf",
                                    enabled: controller
                                        .acceptTermsAndConditions.value,
                                    onClick: controller.isLoading.isTrue
                                        ? null
                                        : () {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                            controller.acceptTermsAndConditions
                                                .toggle();
                                          },
                                  ),
                                  if (controller.isLandlord)
                                    (
                                      label: "Landlord Agreement",
                                      pdf: "assets/pdf/landlord_agreement.pdf",
                                      enabled:
                                          controller.acceptLandlordPolicy.value,
                                      onClick: controller.isLoading.isTrue
                                          ? null
                                          : () {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              controller.acceptLandlordPolicy
                                                  .toggle();
                                            },
                                    ),
                                ].map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                      horizontal: 10.0,
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: controller.isLoading.isTrue
                                              ? null
                                              : () {
                                                  Get.to(() => ViewPdfScreen(
                                                      title: e.label,
                                                      asset: e.pdf));
                                                },
                                          child: Text(
                                            e.label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: ROOMY_ORANGE,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: e.onClick,
                                          child: Icon(
                                            e.enabled
                                                ? Icons
                                                    .check_circle_outline_outlined
                                                : Icons.circle_outlined,
                                            color: ROOMY_ORANGE,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList()),
                          ],
                        ),
                      ),

                      // Credentials
                      SingleChildScrollView(
                        child: Form(
                          key: controller._formkeyCredentials,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InlineTextField(
                                initialValue:
                                    controller.information["firstName"],
                                enabled: controller.isLoading.isFalse,
                                labelText: 'firstName'.tr,
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
                                labelText: 'lastName'.tr,
                                initialValue:
                                    controller.information["lastName"],
                                enabled: controller.isLoading.isFalse,
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
                                labelText: 'gender'.tr,
                                value: controller.information["gender"],
                                items: const ["Male", "Female", "N/A"],
                                onChanged: controller.isLoading.isTrue
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          controller.information["gender"] =
                                              val;
                                        }
                                      },
                              ),
                              const SizedBox(height: 10),
                              const SizedBox(height: 10),
                              InlineTextField(
                                labelText: 'password'.tr,
                                initialValue:
                                    controller.information["password"],
                                enabled: controller.isLoading.isFalse,
                                obscureText: controller.showPassword.isFalse,
                                suffixIcon: IconButton(
                                  onPressed: controller.showPassword.toggle,
                                  icon: controller.showPassword.isFalse
                                      ? const Icon(CupertinoIcons.eye)
                                      : const Icon(CupertinoIcons.eye_slash),
                                ),
                                onChanged: (value) =>
                                    controller.information["password"] = value,
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
                              InlineTextField(
                                labelText: 'confirmPassword'.tr,
                                initialValue:
                                    controller.information["confirmPassword"],
                                enabled: controller.isLoading.isFalse,
                                obscureText:
                                    controller.showConfirmPassword.isFalse,
                                suffixIcon: IconButton(
                                  onPressed:
                                      controller.showConfirmPassword.toggle,
                                  icon: controller.showPassword.isFalse
                                      ? const Icon(CupertinoIcons.eye)
                                      : const Icon(CupertinoIcons.eye_slash),
                                ),
                                onChanged: (value) => controller
                                    .information["confirmPassword"] = value,
                                validator: (value) {
                                  if (value !=
                                      controller.information["password"]) {
                                    return 'passwordMustHaveMatch'.tr;
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              InlinePhoneNumberInput(
                                initialValue: controller.phoneNumber,
                                labelText: "phoneNumber".tr,
                                onChange: (phoneNumber) {
                                  controller.phoneNumber = phoneNumber;
                                },
                              ),
                              const SizedBox(height: 10),
                              InlineDropdown<String>(
                                labelText: 'country'.tr,
                                value: controller.information["country"],
                                items: ["N/A", ...allCountriesNames],
                                onChanged: controller.isLoading.isTrue
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          controller.information["country"] =
                                              val;
                                        }
                                      },
                              ),
                              const SizedBox(height: 10),

                              // Profile picture
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: controller._viewPropfilePicture,
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: controller
                                              ._images.isNotEmpty
                                          ? FileImage(
                                              File(controller._images[0].path))
                                          : null,
                                      child: controller._images.isNotEmpty
                                          ? null
                                          : const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (context) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading:
                                                    const Icon(Icons.camera),
                                                title: const Text("Camera"),
                                                onTap: () {
                                                  Get.back();
                                                  controller
                                                      ._pickProfilePicture(
                                                          gallery: false);
                                                },
                                              ),
                                              const Divider(),
                                              ListTile(
                                                leading:
                                                    const Icon(Icons.image),
                                                title: const Text("Gallery"),
                                                onTap: () {
                                                  Get.back();
                                                  controller
                                                      ._pickProfilePicture();
                                                },
                                              ),
                                              const Divider(),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ),
                                                title: const Text("Cancel"),
                                                onTap: () {
                                                  Get.back();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Text("Add profile picture"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // const Divider(height: 30),
                              // Center(
                              //   child: TextButton(
                              //     onPressed: () =>
                              //         Get.off(() => const LoginScreen()),
                              //     child: const Text(
                              //       'Login',
                              //       style: TextStyle(
                              //         color: ROOMY_PURPLE,
                              //         fontWeight: FontWeight.bold,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),

                      // Verification
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            if (controller._pageIndex.value == 2)
                              FutureBuilder(
                                future: controller._formattedPhoneNumber,
                                builder: (ctx, asp) {
                                  return Text(
                                    'enterTheVerificationCodeSentTo'.trParams(
                                      {"phoneNumber": asp.data ?? ""},
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.watch_later_outlined),
                                const SizedBox(width: 10),
                                Obx(() {
                                  final minutes =
                                      controller.secondsLeft.value ~/ 60;
                                  final seconds = controller.secondsLeft.value -
                                      minutes * 60;

                                  return Text("$minutes Mins $seconds Sec");
                                }),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Pinput(
                                length: 6,
                                onCompleted: (val) {
                                  if (controller.secondsLeft.value <= 0) {
                                    showToast("Verification time out");
                                  } else {
                                    controller._saveCredentials(val);
                                  }
                                  // controller.saveCredentials(val);
                                },
                                controller: controller._piniputController,
                                defaultPinTheme: PinTheme(
                                  height: 40,
                                  width: 35,
                                  textStyle: const TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 56, 94, 128),
                                      fontWeight: FontWeight.w600),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 161, 163, 165),
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            Text('didNotReicievedCode'.tr),
                            TextButton(
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : controller.sendSmsCode,
                              child: Text('resend'.tr),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.isLoading.isTrue)
                  Container(
                    alignment: Alignment.center,
                    color: Colors.grey.withOpacity(0.4),
                    child: CircularProgressIndicator(
                      color: Colors.grey.withOpacity(0.8),
                      strokeWidth: 2,
                    ),
                  )
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            decoration: const BoxDecoration(
              color: ROOMY_PURPLE,
              borderRadius: BorderRadius.vertical(
                top: Radius.elliptical(30, 10),
              ),
            ),
            child: Builder(builder: (context) {
              if (controller._pageIndex.value == 2) {
                return const SizedBox();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : () => Get.off(() => const LoginScreen()),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : () async {
                            switch (controller._pageIndex.value) {
                              case 0:
                                final isValid =
                                    await controller._validateFisrtPage();
                                if (!isValid) return;

                                controller._moveToPage(1);
                                break;
                              case 1:
                                final isValid =
                                    await controller._validateCredentials();
                                if (!isValid) return;

                                controller.sendSmsCode();
                                break;
                              default:
                            }
                          },
                    icon: const Icon(
                      CupertinoIcons.chevron_right_circle,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  // const Icon(Icons.arrow_right),
                ],
              );
            }),
          ),
        );
      }),
    );
  }
}
