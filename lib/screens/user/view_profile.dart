import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/prompt_user_password.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/screens/user/delete_account.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';
import "package:path/path.dart" as path;

class _ViewProfileController extends LoadingController {
  final _formKey = GlobalKey<FormState>();
  final _showPassword = false.obs;
  var newPassword = '';

  final Rx<num> _accountBanlace = 0.obs;

  final isFectchingBalance = false.obs;

  final _images = <CroppedFile>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchBalance();
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
              toolbarColor: Colors.green,
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
          isLoading(true);
          await _updateProfile();
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

  Future<void> _updateProfile() async {
    try {
      isLoading(true);

      final imgRef = FirebaseStorage.instance
          .ref()
          .child('images')
          .child("profile-pictures")
          .child(
              '/${createDateTimeFileName()}${path.extension(_images[0].path)}');

      final uploadTask =
          imgRef.putData(await File(_images[0].path).readAsBytes());

      String imageUrl = await (await uploadTask).ref.getDownloadURL();

      final res = await ApiService.getDio.put(
        '/profile/profile-picture',
        data: {"profilePicture": imageUrl},
      );

      switch (res.statusCode) {
        case 200:
          if (Get.context != null) {
            await precacheImage(NetworkImage(imageUrl), Get.context!);
          }
          showToast("Profile updated successfully".tr);
          AppController.instance.user.update((val) {
            if (val != null) {
              val.profilePicture = imageUrl;
            }
          });
          AppController.saveUser(AppController.me);
          update();
          break;
        default:
          deleteFileFromUrl(imageUrl);
          break;
      }
    } catch (e) {
      Get.log("$e");
      showToast('someThingWentWrong'.tr);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _fetchBalance() async {
    try {
      isFectchingBalance(true);
      update();

      final res = await ApiService.getDio.get("/profile/account-balance");

      if (res.statusCode == 200) {
        _accountBanlace(res.data["accountBanlance"]);
      }

      update();
    } catch (_) {
    } finally {
      isFectchingBalance(false);
      update();
    }
  }

  Future<void> _toggleShowPassword() async {
    if (_showPassword.isTrue) {
      _showPassword(false);
      update();
      return;
    }

    final password = await promptUserPassword(Get.context!);

    if (password == null) return;

    if (password == AppController.instance.user.value.password) {
      _showPassword(true);
    } else {
      showToast("Incorrect password".tr);
    }
    update();
  }

  Future<void> _changePassword(BuildContext context) async {
    var showOldPassword = false;
    var showNewPassword = false;
    var showConfirmNewPassword = false;
    final password = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 10,
            right: 10,
            left: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(builder: (context, StateSetter setState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Change password".tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // old password
                    InlineTextField(
                      obscureText: !showOldPassword,
                      hintText: 'Enter old password'.tr,
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value !=
                            AppController.instance.user.value.password) {
                          return 'Incorrect password'.tr;
                        }

                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => showOldPassword = !showOldPassword),
                        icon: showOldPassword
                            ? const Icon(CupertinoIcons.eye)
                            : const Icon(CupertinoIcons.eye_slash),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // new password
                    InlineTextField(
                      obscureText: !showNewPassword,
                      onChanged: (value) {
                        newPassword = value;
                      },
                      hintText: "Enter new password",
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'thisFieldIsRequired'.tr;
                        }

                        if (value.length < 8) {
                          return 'weakPassword'.tr;
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => showNewPassword = !showNewPassword),
                        icon: showNewPassword
                            ? const Icon(CupertinoIcons.eye)
                            : const Icon(CupertinoIcons.eye_slash),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // confirm new password
                    InlineTextField(
                      obscureText: !showConfirmNewPassword,
                      hintText: "Confirm password",
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value != newPassword) {
                          return 'passwordDontMatch'.tr;
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: () => setState(() =>
                            showConfirmNewPassword = !showConfirmNewPassword),
                        icon: showConfirmNewPassword
                            ? const Icon(CupertinoIcons.eye)
                            : const Icon(CupertinoIcons.eye_slash),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(result: null),
                          child: Text("cancel".tr),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Get.back(result: newPassword);
                            }
                          },
                          child: Text("ok".tr),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );

    if (password != null) {
      try {
        isLoading(false);
        final res =
            await ApiService.getDio.put("$API_URL/profile/password", data: {
          "oldPassword": AppController.instance.user.value.password,
          "newPassword": password,
        });

        switch (res.statusCode) {
          case 403:
            showToast("Incorrect password".tr, severity: Severity.error);
            break;
          case 200:
            showToast("Password updated successfully".tr);

            AppController.instance.userPassword = password;
            AppController.saveUserPassword(password);

            break;
          default:
            showToast("someThingWentWrong".tr, severity: Severity.error);
            break;
        }
      } catch (e) {
        showToast("someThingWentWrong".tr, severity: Severity.error);
      } finally {
        isLoading(false);
      }
    }

    newPassword = "";
  }

  Future<void> _handleDeleteAccountTapped() async {
    final shouldContinue = await showConfirmDialog(
      DELETE_ACCOUNT_MESSAGE,
      title: 'Delete Account',
    );

    if (shouldContinue == true) {
      Get.to(() => const DeleteAccountScreen());
    }
  }
}

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(_ViewProfileController());
    final me = AppController.instance.user.value;

    return Scaffold(
      body: GetBuilder<_ViewProfileController>(
        builder: (controller) {
          final textTheme = Theme.of(context).textTheme;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    actions: [
                      IconButton(
                          onPressed: () async {
                            await Get.to(() => const UpdateUserProfile());
                            controller.update();
                          },
                          icon: const Icon(Icons.edit))
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      expandedTitleScale: 1.2,
                      title: Text(me.fullName),
                      centerTitle: true,
                      background: Hero(
                        tag: "profile-picture-hero",
                        child: Obx(() {
                          if (AppController
                                  .instance.user.value.profilePicture ==
                              null) {
                            return Image.asset(
                              AppController.instance.user.value.gender == "Male"
                                  ? "assets/images/default_male.png"
                                  : "assets/images/default_female.png",
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              Get.to(
                                () {
                                  return ViewImages(
                                    title: "Profile picture",
                                    images: [
                                      CachedNetworkImageProvider(
                                        AppController.instance.user.value
                                            .profilePicture!,
                                      )
                                    ],
                                  );
                                },
                                transition: Transition.zoom,
                              );
                            },
                            child: LoadingProgressImage(
                              image: CachedNetworkImageProvider(AppController
                                  .instance.user.value.profilePicture!),
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : () => controller._pickProfilePicture(
                                      gallery: false),
                              icon: const Icon(Icons.camera),
                              label: Text(
                                "camera".tr,
                                style: const TextStyle(),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : () => controller._pickProfilePicture(),
                              icon: const Icon(Icons.image),
                              label: Text(
                                "pictures".tr,
                                style: const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                        Card(
                          child: ListTile(
                            title: Text(
                              "Full name".tr,
                              style: textTheme.bodySmall!,
                            ),
                            subtitle: Text(me.fullName),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(left: 16),
                            title: Text("password".tr,
                                style: textTheme.bodySmall!),
                            subtitle: Text(
                              controller._showPassword.isTrue
                                  ? '${me.password}'
                                  : "•" * 10,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: controller._toggleShowPassword,
                                  icon: controller._showPassword.isTrue
                                      ? const Icon(Icons.visibility_off)
                                      : const Icon(Icons.visibility),
                                ),
                                IconButton(
                                  onPressed: () {
                                    controller._changePassword(context);
                                  },
                                  icon: const Icon(Icons.settings),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Label(label: "Full name", value: me.fullName),
                                Label(label: "Email", value: me.email),
                                Label(label: "Phone", value: me.phone ?? "N/A"),
                                Label(
                                    label: "Gender", value: me.gender ?? "N/A"),
                                Label(
                                    label: "Country",
                                    value: me.country ?? "N/A"),
                                Label(
                                  label: "Status",
                                  value: me.type.replaceFirst(
                                    me.type[0],
                                    me.type[0].toUpperCase(),
                                  ),
                                ),
                                Label(
                                  label: "Premium",
                                  value: me.isPremium ? "Yes" : "No",
                                ),
                                Label(
                                  label: "Member since",
                                  value: relativeTimeText(me.createdAt),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.person_sharp,
                                color: Colors.red,
                              ),
                            ),
                            title: const Text(
                              "Delete Account",
                              style: TextStyle(color: Colors.red),
                            ),
                            subtitle: const Text(
                              "Total removal of personal information, ads, withdrawal of funds",
                            ),
                            onTap: controller._handleDeleteAccountTapped,
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (controller.isLoading.isTrue) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }
}
