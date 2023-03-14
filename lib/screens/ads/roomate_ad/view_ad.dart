import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class _ViewRoommateAdController extends LoadingController {
  final RoommateAd ad;

  _ViewRoommateAdController(this.ad);

  Future<void> editAd(RoommateAd ad) async {
    Get.to(() => PostRoomateAdScreen(oldData: ad, isPremium: ad.isPremium));
  }

  Future<void> deleteAd(RoommateAd ad) async {
    final shouldContinue = await showConfirmDialog(
      "Do you really want to delete this ad",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);
      final res = await ApiService.getDio.delete("/ads/roommate-ad/${ad.id}");

      if (res.statusCode == 204) {
        isLoading(false);
        await showConfirmDialog(
          "Ad deleted successfully. You will never"
          " see it again after you leave this screen",
          isAlert: true,
        );
        deleteManyFilesFromUrl(ad.images);
        deleteManyFilesFromUrl(ad.videos);
      } else if (res.statusCode == 404) {
        isLoading(false);
        await showConfirmDialog(
          "Ad not found. It may have been deleted alredy",
          isAlert: true,
        );
      } else if (res.statusCode == 400) {
        isLoading(false);
        var message = "This ad is booked. You must decline all "
            "the bookings releted to this ad before deleting it.";

        if (res.data["free-data"] != null) {
          message += " The cuurent last Check out on this ad is"
              " ${relativeTimeText(DateTime.parse(res.data["free-data"]))}";
        }

        await showConfirmDialog(message, isAlert: true);
      } else {
        showGetSnackbar(
          "Failed to book ad. Please try again",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log("$e");
      showGetSnackbar(
        "Failed to book ad. Please try again",
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> chatWithUser() async {
    final conv = (await ChatConversation.getSavedChat(
            ChatConversation.createConvsertionKey(
                AppController.me.id, ad.poster.id))) ??
        ChatConversation.newConversation(friend: ad.poster);
    Get.to(() => FlyerChatScreen(conversation: conv));
  }

  void _viewImage(String source) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        return CachedNetworkImage(imageUrl: source);
      },
    );
  }
}

class ViewRoommateAdScreen extends StatelessWidget {
  const ViewRoommateAdScreen({super.key, required this.ad});

  final RoommateAd ad;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final controller = Get.put(_ViewRoommateAdController(ad));
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: ad.poster.profilePicture,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  height: 200,
                  // errorWidget: (ctx, e, trace) {
                  //   return const SizedBox(
                  //     width: double.infinity,
                  //     height: 150,
                  //     child: Icon(Icons.broken_image, size: 50),
                  //   );
                  // },
                ),
                const BackButton(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Loooking for roomate",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(ad.description),
                  const Divider(height: 10),
                  const Text("About me", style: TextStyle(fontSize: 14)),
                  Text(
                    "${ad.aboutYou["occupation"]}, "
                    "${ad.poster.gender}(${ad.aboutYou["age"]})",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  GridView.count(
                    crossAxisCount: screenWidth > 370 ? 2 : 1,
                    childAspectRatio: screenWidth > 370 ? 5 : 7,
                    crossAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      DataLabel(
                        icon: Icons.contact_mail,
                        label: "Name",
                        value: ad.poster.fullName,
                      ),
                      DataLabel(
                        icon: Icons.home,
                        label: "Property",
                        value: ad.type,
                      ),
                      DataLabel(
                        icon: Icons.mail_outline,
                        label: "Email",
                        value: ad.poster.email,
                      ),
                      DataLabel(
                        icon: Icons.phone,
                        label: "Contact",
                        value: ad.poster.phone,
                      ),
                      DataLabel(
                        icon: Icons.ac_unit_outlined,
                        label: "Astrological sign",
                        value: "${ad.aboutYou["astrologicalSign"]}",
                      ),
                      DataLabel(
                        icon: Icons.language,
                        label: "Languages",
                        value: (ad.aboutYou['languages'] as List).join(', '),
                      ),
                      DataLabel(
                        icon: Icons.room,
                        label: "Location",
                        value:
                            '${ad.address['country']}, ${ad.address['location']}',
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text(
                    "Interests & Features",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: screenWidth > 370 ? 4 : 3,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    children: [
                      DataLabel(
                        icon: Icons.calendar_month,
                        label: "Moving date",
                        value: Jiffy(ad.movingDate).yMMMEd,
                      ),
                      DataLabel(
                        icon: Icons.tv,
                        label: "TV",
                        value:
                            ad.socialPreferences["tv"] == true ? "Yes" : "No",
                      ),
                      DataLabel(
                        icon: Icons.money,
                        label: "Budget",
                        value: "${ad.budget} AED",
                      ),
                      DataLabel(
                        icon: ad.socialPreferences["drinking"] == true
                            ? Icons.local_drink_sharp
                            : Icons.no_drinks,
                        label: "Drinking",
                        value: ad.socialPreferences["drinking"] == true
                            ? "Yes"
                            : "No",
                      ),
                      DataLabel(
                        icon: Icons.family_restroom,
                        label: "Friend party",
                        value: ad.socialPreferences["friendParty"] == true
                            ? "Yes"
                            : "No",
                      ),
                      DataLabel(
                        icon: Icons.family_restroom,
                        label: "Cooking",
                        value: ad.socialPreferences["cooking"] == true
                            ? "Yes"
                            : "No",
                      ),
                      DataLabel(
                        icon: Icons.smoking_rooms_rounded,
                        label: "Smoking",
                        value: ad.socialPreferences["smoking"] == true
                            ? "Yes"
                            : "No",
                      ),
                      DataLabel(
                        icon: Icons.smoking_rooms_rounded,
                        label: "Swimming",
                        value: ad.socialPreferences["swimming"] == true
                            ? "Yes"
                            : "No",
                      ),
                      DataLabel(
                        icon: ad.socialPreferences["gender"] == "Male"
                            ? Icons.male
                            : Icons.female,
                        label: "Gender preferred",
                        value: "${ad.socialPreferences["gender"]}",
                      ),
                      DataLabel(
                        icon: Icons.group,
                        label: "People",
                        value:
                            "${ad.socialPreferences["numberOfPeople"]} peoples",
                      ),
                      DataLabel(
                        icon: Icons.sports_gymnastics,
                        label: "Gym",
                        value:
                            ad.socialPreferences["gym"] == true ? "Yes" : "No",
                      ),
                      DataLabel(
                        icon: Icons.wifi,
                        label: "WIFI",
                        value:
                            ad.socialPreferences["wifi"] == true ? "Yes" : "No",
                      ),
                      DataLabel(
                        icon: Icons.public,
                        label: "Nationality preferred",
                        value: "${ad.socialPreferences["nationality"]}",
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  Builder(builder: (context) {
                    if (ad.isMine) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : () => controller.editAd(ad),
                                child: const Text("Edit"),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : () => controller.deleteAd(ad),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.isTrue
                            ? null
                            : () => controller.chatWithUser(),
                        child: Text("Chat with ${ad.poster.fullName}"),
                      ),
                    );
                  }),
                  const Divider(height: 10),
                  const Text("Images", style: TextStyle(fontSize: 14)),
                  GridView.count(
                    crossAxisCount: screenWidth > 370 ? 4 : 2,
                    crossAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: ad.images
                        .map(
                          (e) => GestureDetector(
                            onTap: () => controller._viewImage(e),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2.5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: CachedNetworkImage(
                                  imageUrl: e,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Videos", style: TextStyle(fontSize: 14)),
                  if (controller.ad.videos.isNotEmpty)
                    GridView.count(
                      crossAxisCount: screenWidth > 370 ? 4 : 2,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: ad.videos
                          .map(
                            (e) => GestureDetector(
                              onTap: () => Get.to(() {
                                return PlayVideoScreen(
                                    source: e, isAsset: false);
                              }),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: double.infinity,
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 2.5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: FutureBuilder(
                                        builder: (ctx, asp) {
                                          if (asp.hasData) {
                                            return Image.file(
                                              File(asp.data!),
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return Container();
                                        },
                                        future: VideoThumbnail.thumbnailFile(
                                          video: e,
                                          quality: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.play_arrow,
                                    size: 40,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const Divider(height: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DataLabel extends StatelessWidget {
  const DataLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 25),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
            ),
          ],
        )
      ],
    );
  }
}
