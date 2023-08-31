import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/prompt_user_password.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/user/delete_account.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';

class _ViewProfileController extends LoadingController {
  final _formKey = GlobalKey<FormState>();
  final _showPassword = false.obs;
  var newPassword = '';

  final Rx<num> _accountBanlace = 0.obs;

  final isFectchingBalance = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchBalance();
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
    final aboutMe = me.aboutMe;

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
                            await Get.to(() => const UpdateUserProfileScreen());
                            controller.update();
                          },
                          icon: const Icon(Icons.edit))
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      expandedTitleScale: 1.2,
                      centerTitle: true,
                      title: Text(me.fullName),
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
                  SliverPadding(
                    padding: const EdgeInsets.all(10.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          CustomButton('Update my profile',
                              onPressed: () async {
                            await Get.to(() => const UpdateUserProfileScreen());

                            controller.update();
                          }),
                          const SizedBox(height: 10),
                          Card(
                            surfaceTintColor: Colors.white,
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
                            surfaceTintColor: Colors.white,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  (label: "Full name", value: me.fullName),
                                  (label: "Email", value: me.email),
                                  (label: "Phone", value: me.phone ?? "N/A"),
                                  (label: "Gender", value: me.gender ?? "N/A"),
                                  (
                                    label: "Nationality",
                                    value: me.country ?? "N/A"
                                  ),
                                  (
                                    label: "Status",
                                    value: me.type.replaceFirst(
                                      me.type[0],
                                      me.type[0].toUpperCase(),
                                    ),
                                  ),
                                  (
                                    label: "Premium",
                                    value: me.isPremium ? "Yes" : "No",
                                  ),
                                  (
                                    label: "Member since ",
                                    value: Jiffy.parseFromDateTime(me.createdAt)
                                        .toLocal()
                                        .yMMMEdjm,
                                  ),
                                  (
                                    label: "Age:",
                                    value: aboutMe.age ?? "N/A",
                                  ),
                                  (
                                    label: "Occupation:",
                                    value: aboutMe.occupation ?? "N/A",
                                  ),
                                  (
                                    label: "Lifestyle:",
                                    value: aboutMe.lifeStyle ?? "N/A",
                                  ),
                                  (
                                    label: "Sign:",
                                    value: aboutMe.astrologicalSign ?? "N/A",
                                  ),
                                  (
                                    label: "Languages:",
                                    value: aboutMe.languages?.isEmpty == true
                                        ? "N/A"
                                        : aboutMe.languages?.join(", ") ??
                                            "N/A",
                                  ),
                                ].map((e) {
                                  return Label(label: e.label, value: e.value);
                                }).toList(),
                              ),
                            ),
                          ),
                          Card(
                            surfaceTintColor: Colors.white,
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
