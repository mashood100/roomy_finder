import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';

class _PostAdController extends GetxController {
  final adType = AdType.property.obs;
}

class PostAdScreen extends StatelessWidget {
  const PostAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PostAdController());
    return Scaffold(
      appBar: AppBar(
        title: Text("postAd".tr),
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Column(
                children: [
                  Center(
                    child: Text("What type of ad do you want to post?".tr),
                  ),
                  const SizedBox(height: 20),
                  ...[
                    if (AppController.me.isLandlord) AdType.property,
                    AdType.roommateMatch,
                    AdType.roommatePremium,
                  ].map((e) {
                    final String label;
                    switch (e) {
                      case AdType.property:
                        label = 'Property Ad';
                        break;
                      case AdType.roommateMatch:
                        label = 'Roommate Match registration'.tr;
                        break;
                      case AdType.roommatePremium:
                        label = 'Premium Roommate Ad'.tr;
                        break;
                      default:
                        label = 'ad'.tr;
                    }
                    return InkWell(
                      onTap: () => controller.adType(e),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Radio(
                              value: e,
                              groupValue: controller.adType.value,
                              onChanged: (value) {
                                controller.adType(e);
                              },
                            ),
                            Text(
                              label,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              switch (controller.adType.value) {
                case AdType.property:
                  Get.to(() => const PostPropertyAdScreen());
                  break;
                case AdType.roommateMatch:
                  Get.to(() => const PostRoomateAdScreen(isPremium: false));
                  break;
                case AdType.roommatePremium:
                  if (AppController.me.isPremium) {
                    Get.to(() => const PostRoomateAdScreen(isPremium: true));
                  } else {
                    final upgrade = await showConfirmDialog(
                        "Only premium members can post premium ADs."
                        " Do you want to upgrade you plan?");
                    if (upgrade == true) {
                      Get.to(() => UpgragePlanScreen(
                            skipCallback: () {
                              Get.to(() =>
                                  const PostRoomateAdScreen(isPremium: true));
                            },
                          ));
                    }
                  }

                  break;
                default:
              }
            },
            child: Text("next".tr),
          ),
        ),
      ),
    );
  }
}
