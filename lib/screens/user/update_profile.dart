import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import "package:path/path.dart" as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/countries_list.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';

class _UpdateProfileController extends LoadingController {
  final _formkeyCredentials = GlobalKey<FormState>();

  final showPassword = false.obs;
  final showConfirmPassword = false.obs;

  String _emailVerificationCode = "";
  bool _emailIsVerified = false;
  final _isVerifiyingEmail = false.obs;

  // Information
  final accountType = UserAccountType.landlord.obs;
  final information = <String, String?>{};
  final languages = <String>[].obs;
  final _images = <CroppedFile>[].obs;
  String? _oldProfilePicture;

  final aboutMe = <String, Object?>{
    // "nationality": "Arab",
    // "astrologicalSign": "ARIES",
    // "gender": AppController.me.gender,
    // "age": "",
    // "occupation": "Professional",
    // "lifeStyle": "Early Bird",
  }.obs;

  bool get _canVerifyEmail {
    return isLoading.isFalse &&
        AppController.me.email != information["email"] &&
        _isVerifiyingEmail.isFalse &&
        "${information["email"]}".isEmail &&
        !_emailIsVerified;
  }

  @override
  void onInit() {
    information["gender"] = AppController.me.gender;
    information["email"] = AppController.me.email;
    information["firstName"] = AppController.me.firstName;
    information["lastName"] = AppController.me.lastName;

    var ab = AppController.me.aboutMe;
    for (var entry in ab.toMap().entries) {
      if (entry.key == "languages") continue;

      if (entry.value != null) aboutMe[entry.key] = entry.value.toString();
    }

    if (ab.languages != null) languages(ab.languages!);

    _oldProfilePicture = AppController.me.profilePicture;

    super.onInit();
  }

  // ignore: unused_element
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

  Future<void> _saveCredentials() async {
    if (_canVerifyEmail) {
      if (!_emailIsVerified) {
        showToast("Please verify email");
        return;
      }
    }
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

      aboutMe["languages"] = languages;

      var payload = {...information, "aboutMe": aboutMe};

      if (imageUrl != null) payload["profilePicture"] = imageUrl;
      if (imageUrl != null && _oldProfilePicture == null) {
        payload["profilePicture"] = null;
      }

      final res =
          await ApiService.getDio.put("/auth/credentials", data: payload);

      if (res.statusCode == 200) {
        AppController.instance.user.update((val) {
          if (val == null) return;

          val.gender = information["gender"];
          val.email = information["email"] as String;
          val.firstName = information["firstName"] as String;
          val.lastName = information["lastName"] as String;
          val.country = information["country"];

          aboutMe["languages"] = languages;

          val.aboutMe = AboutMe.fromMap(aboutMe);

          val.profilePicture = imageUrl ?? _oldProfilePicture;
        });

        showToast("Info updated successlly");
        _emailVerificationCode = "";
        AppController.saveUser(AppController.me);
      } else {
        showToast("Update failed");
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showToast("Something went wrong. Please try again later");
    } finally {
      isLoading(false);
    }
  }

  ImageProvider? get _profilePicture {
    if (_images.isNotEmpty) {
      return FileImage(File(_images.first.path));
    }

    if (_oldProfilePicture != null) {
      return CachedNetworkImageProvider(AppController.me.profilePicture!);
    }

    return null;
  }

  void _viewPropfilePicture() {
    if (_profilePicture == null) return;

    Get.to(() => ViewImages(images: [_profilePicture!]));
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
              toolbarColor: ROOMY_PURPLE,
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

class UpdateUserProfileScreen extends StatelessWidget {
  const UpdateUserProfileScreen({super.key});

  Widget _createLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

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
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Form(
                key: controller._formkeyCredentials,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // information
                    const SizedBox(height: 10),

                    _createLabel("Email"),
                    InlineTextField(
                      hintText: "emailAddress".tr,
                      initialValue: controller.information["email"],
                      enabled: controller.isLoading.isFalse &&
                          !controller._emailIsVerified,
                      onChanged: (value) {
                        controller.information["email"] = value.toLowerCase();
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

                    const SizedBox(height: 10),
                    // First name
                    _createLabel("First name"),
                    InlineTextField(
                      initialValue: controller.information["firstName"],
                      enabled: controller.isLoading.isFalse,
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
                    // Last name
                    _createLabel("Last name"),
                    InlineTextField(
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
                    _createLabel("Gender"),
                    InlineDropdown<String>(
                      hintText: "Select your gender",
                      value: controller.information["gender"],
                      items: ALL_GENDERS,
                      onChanged: controller.isLoading.isTrue
                          ? null
                          : (val) {
                              if (val != null) {
                                controller.information["gender"] = val;
                              }
                            },
                    ),
                    const SizedBox(height: 10),

                    // Country
                    _createLabel("Nationality"),
                    InlineDropdown<String>(
                      hintText: "Select",
                      value: controller.information["country"],
                      items: COUNTRIES_LIST.map((e) => e.name).toList(),
                      onChanged: controller.isLoading.isTrue
                          ? null
                          : (val) {
                              if (val != null) {
                                controller.information["country"] = val;
                              }
                            },
                    ),

                    const SizedBox(height: 10),
                    // Age
                    _createLabel("Age"),
                    InlineTextField(
                      suffixText: "Years old",
                      hintText: "Example 28",
                      initialValue: controller.aboutMe["age"]?.toString(),
                      enabled: controller.isLoading.isFalse,
                      onChanged: (value) {
                        controller.aboutMe["age"] = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        final numValue = int.tryParse(value);

                        if (numValue == null || numValue > 80) {
                          return 'The maximum age is 80'.tr;
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Employment
                    _createLabel("Employment"),
                    InlineDropdown<String>(
                      hintText: "Select",
                      value: controller.aboutMe["occupation"] as String?,
                      items: ALL_OCCUPATIONS,
                      onChanged: (val) {
                        if (val != null) {
                          controller.aboutMe["occupation"] = val;
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Sign
                    _createLabel("Astrological sign"),
                    InlineDropdown<String>(
                      hintText: "Select",
                      value: controller.aboutMe["astrologicalSign"] as String?,
                      items: ASTROLOGICAL_SIGNS.map((e) => e.value).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.aboutMe["astrologicalSign"] = val;
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // lifeStyle
                    _createLabel("Life style"),
                    InlineDropdown<String>(
                      hintText: "Select",
                      value: controller.aboutMe["lifeStyle"] as String?,
                      items: ALL_LIFE_STYLES,
                      onChanged: (val) {
                        if (val != null) {
                          controller.aboutMe["lifeStyle"] = val;
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    Text('Languages you speak'.tr),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      // padding: const EdgeInsets.all(10),
                      child: Wrap(
                        children: [
                          ...controller.languages.map((e) {
                            return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                padding: const EdgeInsets.only(left: 15),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(e),
                                    SizedBox(
                                      height: 35,
                                      child: IconButton(
                                        onPressed: () {
                                          controller.languages.remove(e);
                                        },
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  ],
                                ));
                          }).toList(),
                          IconButton(
                            onPressed: () async {
                              FocusScope.of(context).unfocus();
                              final result = await filterListData(
                                ALL_LANGUAGUES,
                                excluded: controller.languages,
                              );
                              controller.languages.addAll(result);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          )
                        ],
                      ),
                    ),

                    //Save button

                    const Divider(height: 20),
                    // Profile picture
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: controller._viewPropfilePicture,
                          child: CircleAvatar(
                            radius: 50,
                            foregroundImage: controller._profilePicture,
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
                                          leading: const Icon(Icons.camera),
                                          title: const Text("Camera"),
                                          onTap: () {
                                            Get.back();
                                            controller._pickProfilePicture(
                                                gallery: false);
                                          },
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading: const Icon(Icons.image),
                                          title: const Text("Gallery"),
                                          onTap: () {
                                            Get.back();
                                            controller._pickProfilePicture();
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
                              child: Text(controller._profilePicture == null
                                  ? "Add Photo"
                                  : "Change Phone"),
                            ),
                            if (controller._profilePicture != null)
                              TextButton(
                                onPressed: () {
                                  controller._images.clear();
                                  controller._oldProfilePicture = null;
                                  controller.update();
                                },
                                child: const Text("Remove Photo"),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: ROOMY_ORANGE,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(color: ROOMY_ORANGE),
                        ),
                        onPressed: () {
                          controller._saveCredentials();
                        },
                        child: const Text(
                          "SAVE",
                          style: TextStyle(
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
            if (controller.isLoading.isTrue) const LoadingPlaceholder(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }
}
