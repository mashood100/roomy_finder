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
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:uuid/uuid.dart';
import "package:path/path.dart" as path;

class _RegistrationController extends LoadingController {
  final _formkeyCredentials = GlobalKey<FormState>();

  final _isVerifyingPhone = false.obs;

  late final PageController _pageController;
  final _piniputController = TextEditingController();
  final _pageIndex = 0.obs;
  final _gender = "Male".obs;

  final showPassword = false.obs;
  final showConfirmPassword = false.obs;
  final acceptTermsAndConditions = false.obs;
  PhoneNumber phoneNumber = PhoneNumber(dialCode: "971", isoCode: "AE");

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
    secondsLeft(59);
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

  void _moveToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
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

      final res = await ApiService.getDio.post(
        "/auth/credentials",
        data: {
          ...information,
          "type": accountType.value.name,
          "phone": phoneNumber.phoneNumber,
          "fcmToken": await FirebaseMessaging.instance.getToken(),
          "profilePicture": imageUrl,
        },
      );

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
        showGetSnackbar(
          "You need to read and accept the terms and conditions before continuing"
              .tr,
          severity: Severity.error,
        );
        return false;
      }
      isLoading(true);

      final exist =
          await ApiService.checkIfUserExist('${phoneNumber.phoneNumber}');

      if (exist) {
        showGetSnackbar(
          "This phone number already have an account. Please login instead".tr,
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
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 5,
                  bottom: 60,
                ),
                child: PageView(
                  controller: controller._pageController,
                  onPageChanged: (index) => controller._pageIndex(index),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Column(
                      children: <UserAccountType>[
                        UserAccountType.landlord,
                        UserAccountType.tenant,
                        UserAccountType.roommate,
                      ].map((e) {
                        final title = e.name.toLowerCase();
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: RadioListTile<UserAccountType>(
                            value: e,
                            groupValue: controller.accountType.value,
                            onChanged: (value) {
                              if (value != null) controller.accountType(value);
                            },
                            title: Text(
                              title.replaceFirst(
                                  title[0], title[0].toUpperCase()),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Credentials
                    SingleChildScrollView(
                      child: Form(
                        key: controller._formkeyCredentials,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: controller._viewPropfilePicture,
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundImage: controller
                                            ._images.isNotEmpty
                                        ? FileImage(
                                            File(controller._images[0].path))
                                        : null,
                                    child: controller._images.isNotEmpty
                                        ? null
                                        : const Icon(
                                            CupertinoIcons.person_alt_circle,
                                            size: 50,
                                          ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("yourPhoto".tr),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () =>
                                            controller._pickProfilePicture(),
                                        icon: const Icon(Icons.image),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () =>
                                            controller._pickProfilePicture(
                                                gallery: false),
                                        icon: const Icon(Icons.camera),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // information
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                                border:
                                    Border.all(color: Colors.black54, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Text("Gender"),
                                  const Spacer(),
                                  Radio(
                                    value: "Male",
                                    groupValue: controller._gender.value,
                                    onChanged: (value) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      controller.information["gender"] = "Male";
                                      if (value != null) {
                                        controller._gender(value);
                                      }
                                    },
                                  ),
                                  const Text("Male"),
                                  Radio(
                                    value: "Female",
                                    groupValue: controller._gender.value,
                                    onChanged: (value) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      controller.information["gender"] =
                                          "Female";
                                      if (value != null) {
                                        controller._gender(value);
                                      }
                                    },
                                  ),
                                  const Text("Female"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text("emailAddress".tr),
                            TextFormField(
                              initialValue: controller.information["email"],
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'emailAddress'.tr,
                                suffixIcon: const Icon(CupertinoIcons.mail),
                              ),
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
                            Text("firstName".tr),
                            TextFormField(
                              initialValue: controller.information["firstName"],
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'firstName'.tr,
                                suffixIcon: const Icon(CupertinoIcons.person),
                              ),
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
                            Text("lastName".tr),
                            TextFormField(
                              initialValue: controller.information["lastName"],
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'lastName'.tr,
                                suffixIcon: const Icon(CupertinoIcons.person),
                              ),
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
                            Text("password".tr),
                            TextFormField(
                              initialValue: controller.information["password"],
                              enabled: controller.isLoading.isFalse,
                              obscureText: controller.showPassword.isFalse,
                              decoration: InputDecoration(
                                hintText: 'password'.tr,
                                suffixIcon: IconButton(
                                  onPressed: controller.showPassword.toggle,
                                  icon: controller.showPassword.isFalse
                                      ? const Icon(CupertinoIcons.eye)
                                      : const Icon(CupertinoIcons.eye_slash),
                                ),
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
                            Text("confirmPassword".tr),
                            TextFormField(
                              initialValue:
                                  controller.information["confirmPassword"],
                              enabled: controller.isLoading.isFalse,
                              obscureText:
                                  controller.showConfirmPassword.isFalse,
                              decoration: InputDecoration(
                                hintText: 'confirmPassword'.tr,
                                suffixIcon: IconButton(
                                  onPressed:
                                      controller.showConfirmPassword.toggle,
                                  icon: controller.showPassword.isFalse
                                      ? const Icon(CupertinoIcons.eye)
                                      : const Icon(CupertinoIcons.eye_slash),
                                ),
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
                            Text("phoneNumber".tr),
                            PhoneNumberInput(
                              initialValue: controller.phoneNumber,
                              hintText: "phoneNumber".tr,
                              onChange: (phoneNumber) {
                                controller.phoneNumber = phoneNumber;
                              },
                            ),
                            const SizedBox(height: 10),
                            Text("country".tr),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                hintText: 'country'.tr,
                              ),
                              value: controller.information["country"],
                              items: allCountriesNames
                                  .map((e) => DropdownMenuItem<String>(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: controller.isLoading.isTrue
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        controller.information["country"] = val;
                                      }
                                    },
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: controller
                                        .acceptTermsAndConditions.value,
                                    onChanged: controller.isLoading.isTrue
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              controller
                                                  .acceptTermsAndConditions(
                                                      value);
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 20),
                                  Text("termsAndConditions".tr)
                                ],
                              ),
                            ),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),

                    // Verification
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Builder(builder: (context) {
              if (controller._pageIndex.value == 2) {
                return const SizedBox();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                      color: const Color.fromRGBO(96, 15, 116, 1),
                      value: (controller._pageIndex.value + 1) / 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // const SizedBox(width: 10),
                      TextButton(
                        onPressed: controller.isLoading.isTrue ||
                                controller._isVerifyingPhone.isTrue
                            ? null
                            : () {
                                if (controller._pageIndex.value == 0) {
                                  Get.back();
                                } else {
                                  controller._moveToPreviousPage();
                                }
                              },
                        // icon: const Icon(Icons.arrow_left),
                        child: controller._pageIndex.value == 0
                            ? Text("back".tr)
                            : Text("previous".tr),
                      ),

                      TextButton(
                        onPressed: controller.isLoading.isTrue ||
                                controller._isVerifyingPhone.isTrue
                            ? null
                            : () async {
                                switch (controller._pageIndex.value) {
                                  case 0:
                                    controller._moveToNextPage();
                                    break;
                                  case 1:
                                    final isValid =
                                        await controller.validateCredentials();
                                    if (!isValid) return;
                                    controller.sendSmsCode();
                                    break;
                                  default:
                                }
                              },
                        child: Text("next".tr),
                      ),
                      // const Icon(Icons.arrow_right),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      }),
    );
  }
}
