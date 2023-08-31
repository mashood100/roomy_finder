import 'dart:async';

import 'dart:io';

import 'package:flutter/services.dart';
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

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/exceptions.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/countries_list.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/start/roommate_post_registration.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/screens/utility_screens/view_pdf.dart';
import 'package:roomy_finder/utilities/data.dart';

class _RegistrationController extends LoadingController {
  final _formkeyCredentials = GlobalKey<FormState>();

  late final PageController _pageController;
  final _piniputController = TextEditingController();
  final _pageIndex = 0.obs;

  final showPassword = false.obs;
  final showConfirmPassword = false.obs;
  final acceptTermsAndConditions = false.obs;
  final acceptLandlordPolicy = false.obs;
  PhoneNumber phoneNumber = PhoneNumber(dialCode: "971", isoCode: "AE");

  bool get isRoommate => accountType.value == UserAccountType.roommate;
  bool get isLandlord => accountType.value == UserAccountType.landlord;
  bool get isMaintenant => accountType.value == UserAccountType.maintainer;

  // Information
  final accountType = UserAccountType.none.obs;
  final _images = <CroppedFile>[].obs;
  final information = <String, String?>{};

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

  final _haveProviderImageError = false.obs;

  ImageProvider? get _profilePicture {
    if (_images.isNotEmpty) {
      return FileImage(File(_images.first.path));
    }

    return null;
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
      update();
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
    if (_profilePicture == null) return;

    Get.to(() => ViewImages(images: [_profilePicture!]));
  }

  Future<void> _saveCredentials(String otpCode) async {
    try {
      isLoading(true);

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
        if (res.data["code"] == "phone-is-used") {
          showGetSnackbar(
            "This phone number already have an account",
            title: "Registration",
            severity: Severity.info,
          );
        } else {
          showGetSnackbar(
            "thisUserAlreadyExistPleaseLogin".tr,
            title: "registration".tr,
            severity: Severity.info,
          );
        }
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

        await AppController.saveUser(user);
        await AppController.saveUserPassword(information["password"]!);

        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance
              .signInWithCustomToken(res.data["firebaseToken"]);
        }

        if (user.isMaintenant) {
          Get.offAllNamed("/maintenance");
          FirebaseMessaging.instance.subscribeToTopic("maintenance-broadcast");
        } else {
          Get.offAllNamed("/home");
          if (user.isLandlord) {
            RoomyNotificationHelper.showLandlordWelcome();

            Future.delayed(const Duration(minutes: 2), () {
              RoomyNotificationHelper.showLandlordStartMangingYourSpace();
            });

            Future.delayed(const Duration(minutes: 5), () {
              RoomyNotificationHelper.showLandlordHaveNotYetPosted();
            });
          } else if (user.isRoommate) {
            RoomyNotificationHelper.showRoommateWelcome();
            Get.to(() => const RoommatePostRegistrationScreen());
          }
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

      if (accountType.value == UserAccountType.none) {
        showToast("Please choose an account type");
        return false;
      }
      if (acceptTermsAndConditions.isFalse) {
        showToast("Please accept terms and conditions");
        return false;
      }
      if (acceptLandlordPolicy.isFalse && isLandlord) {
        showToast("Please accept landlord policies");
        return false;
      }

      isLoading(true);

      final emailIsUsed =
          await ApiService.checkIfUserExist(information["email"]!);

      if (emailIsUsed) {
        showGetSnackbar(
          "This email address already have an account. Please login instead",
          title: "Registration",
          severity: Severity.info,
        );
        isLoading(false);
        return false;
      }
      final phoneIsUsed =
          await ApiService.checkIfPhoneIsUsed(phoneNumber.phoneNumber!);

      if (phoneIsUsed) {
        showGetSnackbar(
          "An account already exsist with this phone number.",
          title: "Registration",
          severity: Severity.info,
        );
        isLoading(false);
        return false;
      }

      return true;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar("Some thing went wrong".tr, severity: Severity.error);
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
          update();
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

    var accountTypes = [
      (
        value: UserAccountType.roommate,
        label: "ROOMMATE",
        asset: AssetIcons.homeSearchPNG,
        description: "Find shared living options: rooms / bed spaces /"
            " partitions & connect with potential roommates.",
      ),
      (
        value: UserAccountType.landlord,
        label: "LANDLORD",
        asset: AssetIcons.homeKeyPNG,
        description: "List & manage your rental properties, connect with"
            " potential tenants, track rent payments & maintenance requests.",
      ),
      (
        value: UserAccountType.maintainer,
        label: "MAINTAINER",
        asset: AssetIcons.homeRepairPNG,
        description: "Offer your maintenance services to property"
            " landlords & receive maintenance requests.",
      ),
    ];

    const labeStyle = TextStyle(fontWeight: FontWeight.bold);

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
            leading: const BackButton(),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Stack(
              children: [
                Container(
                  height: 15,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Get.theme.appBarTheme.backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.elliptical(50, 25),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 50),
                  child: PageView(
                    controller: controller._pageController,
                    onPageChanged: (index) => controller._pageIndex(index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Account type
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome!\nWhich role suits you best?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),
                            ...accountTypes.map((e) {
                              var isSelected =
                                  e.value == controller.accountType.value;

                              return GestureDetector(
                                onTap: () {
                                  if (e.value == UserAccountType.maintainer) {
                                    showToast(
                                        "Coming soon. Maintenance isn't available on this version");
                                    return;
                                  }
                                  controller.accountType(e.value);
                                  controller.update();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: isSelected
                                        ? Border.all(
                                            width: 2, color: ROOMY_PURPLE)
                                        : Border.all(width: 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 10,
                                  ),
                                  margin: const EdgeInsets.only(
                                    bottom: 20,
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        e.asset,
                                        height: 50,
                                        width: 50,
                                        color: isSelected ? ROOMY_ORANGE : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              e.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              e.description,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w300,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList()
                          ],
                        ),
                      ),

                      // Credentials
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: controller._formkeyCredentials,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Text("Email", style: labeStyle),
                              InlineTextField(
                                hintText: "Enter your email address",
                                initialValue: controller.information["email"],
                                enabled: controller.isLoading.isFalse,
                                onChanged: (value) {
                                  controller.information["email"] =
                                      value.toLowerCase();
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
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),

                              const SizedBox(height: 20),
                              const Text("First name", style: labeStyle),
                              InlineTextField(
                                initialValue:
                                    controller.information["firstName"],
                                enabled: controller.isLoading.isFalse,
                                hintText: "Enter your first name",
                                onChanged: (value) =>
                                    controller.information["firstName"] = value,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                              const Text("Last name", style: labeStyle),
                              InlineTextField(
                                hintText: "Enter your last name",
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
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                              const Text("Gender", style: labeStyle),
                              InlineDropdown<String>(
                                hintText: "Select your gender",
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
                              const SizedBox(height: 20),

                              const Text("Password", style: labeStyle),
                              InlineTextField(
                                hintText: "Enter a password",
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

                              const SizedBox(height: 20),
                              const Text("Confirm", style: labeStyle),
                              InlineTextField(
                                hintText: "Confirm your password",
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
                              const SizedBox(height: 20),
                              const Text("Phone", style: labeStyle),
                              InlinePhoneNumberInput(
                                labelWidth: 0,
                                initialValue: controller.phoneNumber,
                                onChange: (phoneNumber) {
                                  controller.phoneNumber = phoneNumber;
                                },
                              ),
                              const SizedBox(height: 20),

                              const Text("Nationality", style: labeStyle),
                              InlineDropdown<String>(
                                hintText: "Select",
                                value: controller.information["country"],
                                items:
                                    COUNTRIES_LIST.map((e) => e.name).toList(),
                                onChanged: controller.isLoading.isTrue
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          controller.information["country"] =
                                              val;
                                        }
                                      },
                              ),
                              const SizedBox(height: 20),

                              const Text("Age", style: labeStyle),
                              InlineTextField(
                                hintText: "How old are you?",
                                initialValue:
                                    controller.information["aboutMe.age"],
                                enabled: controller.isLoading.isFalse,
                                onChanged: (value) => controller
                                    .information["aboutMe.age"] = value,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }

                                  final age = int.tryParse(value);

                                  if (age == null) return "Invalid age";

                                  if (age < 18) {
                                    return "You must be at least 18 years old to register";
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*'))
                                ],
                              ),

                              const Divider(height: 30),

                              // Profile picture
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: controller._viewPropfilePicture,
                                    child: CircleAvatar(
                                      radius: 50,
                                      foregroundImage:
                                          controller._profilePicture,
                                      onForegroundImageError:
                                          controller._profilePicture == null
                                              ? null
                                              : (e, trace) {
                                                  controller
                                                      ._haveProviderImageError(
                                                          true);
                                                  controller.update();
                                                },
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                                    leading: const Icon(
                                                        Icons.camera),
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
                                                    title:
                                                        const Text("Gallery"),
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
                                        child: Text(
                                            controller._profilePicture == null
                                                ? "Add Photo"
                                                : "Change Phone"),
                                      ),
                                      if (controller._profilePicture != null)
                                        TextButton(
                                          onPressed: () {
                                            controller._images.clear();
                                            controller.update();
                                          },
                                          child: const Text("Remove Photo"),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 30),

                              // Agreements
                              Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    (
                                      label: "Terms & Conditions",
                                      pdf:
                                          "assets/pdf/terms-and-conditions.pdf",
                                      enabled: controller
                                          .acceptTermsAndConditions.value,
                                      onClick: controller.isLoading.isTrue
                                          ? null
                                          : () {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              controller
                                                  .acceptTermsAndConditions
                                                  .toggle();
                                            },
                                    ),
                                    if (controller.isLandlord)
                                      (
                                        label: "Landlord Agreement",
                                        pdf:
                                            "assets/pdf/landlord_agreement.pdf",
                                        enabled: controller
                                            .acceptLandlordPolicy.value,
                                        onClick: controller.isLoading.isTrue
                                            ? null
                                            : () {
                                                FocusManager
                                                    .instance.primaryFocus
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
                                                    Get.to(
                                                      () => ViewPdfScreen(
                                                          title: e.label,
                                                          asset: e.pdf),
                                                    );
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
                                if (controller.accountType.value ==
                                    UserAccountType.none) {
                                  showToast("Please choose account type");
                                  return;
                                }
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
