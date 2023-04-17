import 'dart:async';
import 'dart:io';

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
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/utility_screens/view_pdf.dart';
// import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:uuid/uuid.dart';
import "package:path/path.dart" as path;

class _RegistrationController extends LoadingController {
  final _formkeyCredentials = GlobalKey<FormState>();

  final _isVerifyingPhone = false.obs;
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

  // Information
  final accountType = UserAccountType.landlord.obs;
  final _images = <CroppedFile>[].obs;
  final information = <String, String>{
    "gender": "Male",
    "email": "",
    "firstName": "",
    "lastName": "",
    "password": "",
    "confirmPassword": "",
    "country": allCountriesNames[0],
  };

  String country = "United Arab Emirates";
  String _verificationId = "";

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
      _isVerifyingPhone(true);
      resetSmsTimer();
      secondsLeft(59);
      _piniputController.clear();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber.phoneNumber,
        verificationCompleted: (phoneAuthCredential) {},
        codeSent: (verificationId, forceResendingToken) {
          _isVerifyingPhone(false);
          _verificationId = verificationId;
          if (isLandlord) {
            _moveToPage(3);
          } else {
            _moveToPage(2);
          }
          startSmsTimer();
          _isVerifyingPhone(false);
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: const Duration(minutes: 1),
        verificationFailed: (e) {
          Get.log(" Verification failed with code : ${e.code}");
          _isVerifyingPhone(false);
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
      );
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
      _isVerifyingPhone(false);
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

  Future<void> saveCredentials(String smsCode) async {
    try {
      isLoading(true);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      String? imageUrl;

      if (_images.isNotEmpty) {
        final imgRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child("propile-pictures")
            .child('/${const Uuid().v4()}${path.extension(_images[0].path)}');

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
      };

      data.remove("confirmPassword");

      final res = await ApiService.getDio.post("/auth/credentials", data: data);

      if (res.statusCode == 409) {
        showGetSnackbar(
          "thisUserAlreadyExistPleaseLogin".tr,
          title: "registration".tr,
          severity: Severity.warning,
          action: SnackBarAction(
            label: 'login'.tr,
            onPressed: () => Get.offAndToNamed("/login"),
          ),
        );
        isLoading(false);
        return;
      }

      if (res.statusCode == 500) {
        showGetSnackbar(
          "someThingWentWrong".tr,
          severity: Severity.error,
        );
        isLoading(false);
        return;
      }

      if (res.statusCode == 201) {
        final User user = User.fromMap(res.data);

        AppController.instance.user = user.obs;
        AppController.instance.setIsFirstStart(false);
        AppController.instance.userPassword = information["password"];
        AppController.setupFCMTokenHandler();

        AppNotication.currentUser = user;

        Get.offAllNamed('/home');
      } else {
        throw ApiServiceException(statusCode: res.statusCode);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "invalid-verification-code":
          showGetSnackbar(
            "incorrectVerificationCode".tr,
            title: 'registration'.tr,
            severity: Severity.error,
          );
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

  Future<bool> validateCredentials() async {
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

      final exist = await ApiService.checkIfUserExist(information["email"]!);

      if (exist) {
        showGetSnackbar(
          "This email address already have an account. Please login instead".tr,
          title: "registration".tr,
          severity: Severity.warning,
        );
        isLoading(false);
        return false;
      }

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
                    left: 10,
                    top: 30,
                    right: 10,
                    bottom: 60,
                  ),
                  child: PageView(
                    controller: controller._pageController,
                    onPageChanged: (index) => controller._pageIndex(index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Credentials
                      SingleChildScrollView(
                        child: Form(
                          key: controller._formkeyCredentials,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Account type
                              Row(
                                children: [
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      controller.accountType(
                                          UserAccountType.roommate);
                                    },
                                    child: Icon(
                                      !controller.isLandlord
                                          ? Icons.check_circle_outline_outlined
                                          : Icons.circle_outlined,
                                      color: ROOMY_ORANGE,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      controller.accountType(
                                          UserAccountType.roommate);
                                    },
                                    child: const Text(
                                      "Roommate",
                                      style: TextStyle(
                                        color: ROOMY_PURPLE,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      controller.accountType(
                                          UserAccountType.landlord);
                                    },
                                    child: Icon(
                                      controller.isLandlord
                                          ? Icons.check_circle_outline_outlined
                                          : Icons.circle_outlined,
                                      color: ROOMY_ORANGE,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      controller.accountType(
                                          UserAccountType.landlord);
                                    },
                                    child: const Text(
                                      "Landlord",
                                      style: TextStyle(
                                        color: ROOMY_PURPLE,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const Divider(),
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
                                items: const ["Male", "Female"],
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
                              Row(
                                children: [
                                  Expanded(
                                    child: InlineTextField(
                                      labelText: 'email'.tr,
                                      hintText: "emailAddress".tr,
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
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        side: BorderSide(color: color),
                                      ),
                                      onPressed: !controller._canVerifyEmail
                                          ? null
                                          : controller._verifyEmail,
                                      child: controller
                                              ._isVerifiyingEmail.isTrue
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
                                items: allCountriesNames,
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
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Get.to(() {
                                        return const ViewPdfScreen(
                                          title: "Terms and conditions",
                                          asset:
                                              "assets/pdf/terms-and-conditions.pdf",
                                        );
                                      });
                                    },
                                    child: const Text(
                                      "Terms and conditions",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: ROOMY_ORANGE,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      controller.acceptTermsAndConditions
                                          .toggle();
                                    },
                                    child: Icon(
                                      controller.acceptTermsAndConditions.value
                                          ? Icons.check_circle_outline_outlined
                                          : Icons.circle_outlined,
                                      color: ROOMY_ORANGE,
                                    ),
                                  ),
                                ],
                              ),
                              if (controller.isLandlord)
                                const SizedBox(height: 20),
                              if (controller.isLandlord)
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(() {
                                          return const ViewPdfScreen(
                                            title: "Landlord Agreement",
                                            asset:
                                                "assets/pdf/landlord_agreement.pdf",
                                          );
                                        });
                                      },
                                      child: const Text(
                                        "Landlord Agreement",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: ROOMY_ORANGE,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        controller.acceptLandlordPolicy
                                            .toggle();
                                      },
                                      child: Icon(
                                        controller.acceptLandlordPolicy.value
                                            ? Icons
                                                .check_circle_outline_outlined
                                            : Icons.circle_outlined,
                                        color: ROOMY_ORANGE,
                                      ),
                                    ),
                                  ],
                                ),
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
                            if (controller._pageIndex.value == 1)
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
                                Text("${controller.secondsLeft.value}s"),
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
                                    controller.saveCredentials(val);
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
                  const LinearProgressIndicator(
                    color: Color.fromRGBO(96, 15, 116, 1),
                  ),
                if (controller._isVerifyingPhone.isTrue)
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      // borderRadius: BorderRadius.circular(10),
                    ),
                    child: const CupertinoActivityIndicator(radius: 50),
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
                    onPressed: () => Get.off(() => const LoginScreen()),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: controller.isLoading.isTrue ||
                            controller._isVerifyingPhone.isTrue
                        ? null
                        : () async {
                            switch (controller._pageIndex.value) {
                              case 0:
                                final isValid =
                                    await controller.validateCredentials();
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
