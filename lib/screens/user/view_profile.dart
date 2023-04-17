import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/prompt_user_password.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:uuid/uuid.dart';
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
    AppController.instance.getAccountInfo().then((_) => update());
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
          .child('/${const Uuid().v4()}${path.extension(_images[0].path)}');

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
          AppController.instance.saveUser();
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

  Future<void> _toggleShowPassword(BuildContext context) async {
    if (_showPassword.isTrue) {
      _showPassword(false);
      update();
      return;
    }

    final password = await promptUserPassword(context);

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
                    TextFormField(
                      obscureText: !showOldPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        labelText: 'Old password'.tr,
                        suffixIcon: IconButton(
                          onPressed: () {
                            showOldPassword = !showOldPassword;
                            setState(() {});
                          },
                          icon: showOldPassword
                              ? const Icon(CupertinoIcons.eye_slash_fill)
                              : const Icon(CupertinoIcons.eye_fill),
                        ),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value !=
                            AppController.instance.user.value.password) {
                          return 'Incorrect password'.tr;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // new password
                    TextFormField(
                      obscureText: !showNewPassword,
                      onChanged: (value) {
                        newPassword = value;
                      },
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        labelText: 'New password'.tr,
                        suffixIcon: IconButton(
                          onPressed: () {
                            showNewPassword = !showNewPassword;
                            setState(() {});
                          },
                          icon: showNewPassword
                              ? const Icon(CupertinoIcons.eye_slash_fill)
                              : const Icon(CupertinoIcons.eye_fill),
                        ),
                      ),
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
                      maxLength: 15,
                    ),
                    const SizedBox(height: 10),

                    // confirm new password
                    TextFormField(
                      obscureText: !showConfirmNewPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        labelText: "Confirm password".tr,
                        suffixIcon: IconButton(
                          onPressed: () {
                            showConfirmNewPassword = !showConfirmNewPassword;
                            setState(() {});
                          },
                          icon: showConfirmNewPassword
                              ? const Icon(CupertinoIcons.eye_slash_fill)
                              : const Icon(CupertinoIcons.eye_fill),
                        ),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value != newPassword) {
                          return 'passwordDontMatch'.tr;
                        }
                        return null;
                      },
                      maxLength: 15,
                    ),
                    const SizedBox(height: 10),
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
            if (await AppController.instance.getUserPassword() != null) {
              AppController.instance.saveUserPassword(password);
            }

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
                          return GestureDetector(
                            onTap: () {
                              Get.to(
                                () => ViewImages(
                                  title: "Profile picture",
                                  images: [
                                    CachedNetworkImageProvider(
                                      AppController
                                          .instance.user.value.profilePicture,
                                    )
                                  ],
                                ),
                                transition: Transition.zoom,
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: AppController
                                  .instance.user.value.profilePicture,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorWidget: (context, error, stackTrace) {
                                return Container(
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    CupertinoIcons.profile_circled,
                                    size: 60,
                                  ),
                                );
                              },
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
                            title: Text("password".tr,
                                style: textTheme.bodySmall!),
                            subtitle: Text(
                              controller._showPassword.isTrue
                                  ? '${me.password}'
                                  : "• " * 15,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    controller._toggleShowPassword(context);
                                  },
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
                                Label(label: "Full name", value: me.firstName),
                                Label(label: "Email", value: me.email),
                                Label(label: "Phone", value: me.phone),
                                Label(label: "Gender", value: me.gender),
                                Label(label: "Country", value: me.country),
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
                        )
                      ],
                    ),
                  ),
                  if (controller.isLoading.isTrue)
                    const LinearProgressIndicator()
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
