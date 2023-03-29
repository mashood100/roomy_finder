import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/share_ad.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class _ViewRoommateAdController extends LoadingController {
  final RoommateAd ad;
  final _showAllDescription = false.obs;

  _ViewRoommateAdController(this.ad);

  Future<void> editAd() async {
    Get.to(() => PostRoommateAdScreen(oldData: ad, isPremium: ad.isPremium));
  }

  Future<void> deleteAd() async {
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
    final conv = ChatConversation.newConversation(AppController.me, ad.poster);
    Get.to(() => FlyerChatScreen(conversation: conv));
  }

  void _viewImage(String source) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: Get.context!,
      builder: (context) {
        return SafeArea(
          child: CachedNetworkImage(imageUrl: source),
        );
      },
    );
  }
}

class ViewRoommateAdScreen extends StatelessWidget {
  const ViewRoommateAdScreen({super.key, required this.ad});

  final RoommateAd ad;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ViewRoommateAdController(ad));
    return Scaffold(
      appBar: AppBar(
        title: Text("${ad.type} Roommate"),
        backgroundColor: ROOMY_PURPLE,
        actions: [
          if (!ad.isMine)
            IconButton(
              onPressed: () async {
                await addAdToFavorite(ad.toJson(), "favorites-roommate-ads");
                showToast("Added to favorite");
              },
              icon: const Icon(Icons.favorite, color: ROOMY_ORANGE),
            ),
          IconButton(
            onPressed: () {
              shareAd(ad);
            },
            icon: const Icon(Icons.share),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 1),
            Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...ad.images.map(
                        (e) => GestureDetector(
                          onTap: () => controller._viewImage(e),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(5),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: e,
                                height: 250,
                                width: ad.images.length == 1 ? Get.width : null,
                                fit: ad.images.length == 1
                                    ? BoxFit.cover
                                    : BoxFit.fitHeight,
                                errorWidget: (ctx, e, trace) {
                                  return SizedBox(
                                    width: Get.width,
                                    child: const CupertinoActivityIndicator(
                                      radius: 30,
                                    ),
                                  );
                                },
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) {
                                  return Container(
                                    width: Get.width * 0.9,
                                    padding: const EdgeInsets.all(30),
                                    child: CircularProgressIndicator(
                                      value: downloadProgress.progress,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      ...ad.videos.map(
                        (e) => GestureDetector(
                          onTap: () => Get.to(() {
                            return PlayVideoScreen(source: e, isAsset: false);
                          }),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: FutureBuilder(
                                    builder: (ctx, asp) {
                                      if (asp.hasData) {
                                        return Image.file(
                                          File(asp.data!),
                                          alignment: Alignment.center,
                                          height: 250,
                                          fit: BoxFit.fitHeight,
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
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: 40,
                                  color: Color.fromARGB(255, 2, 3, 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${ad.poster.fullName}, ${ad.aboutYou["age"]}',
                            style: const TextStyle(
                              color: ROOMY_ORANGE,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            ad.action,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (ad.isMine)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ROOMY_PURPLE,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: const BorderSide(color: ROOMY_PURPLE),
                          ),
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : controller.deleteAd,
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ROOMY_ORANGE,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: const BorderSide(color: ROOMY_ORANGE),
                          ),
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : controller.chatWithUser,
                          child: const Text(
                            "Chat",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (ad.isMine) const SizedBox(width: 10),
                      if (ad.isMine)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ROOMY_ORANGE,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: const BorderSide(color: ROOMY_ORANGE),
                          ),
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : controller.editAd,
                          child: const Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.room, color: ROOMY_ORANGE),
                      Text(
                        "${ad.address["city"]}, ${ad.address["location"]}",
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Builder(builder: (context) {
                        final String rentDuration;
                        switch (ad.rentType) {
                          case "Monthly":
                            rentDuration = "Month";
                            break;
                          case "Weekly":
                            rentDuration = "Week";
                            break;
                          default:
                            rentDuration = "Day";
                        }
                        return Text(
                          "Budget ${formatMoney(ad.budget * AppController.convertionRate)}"
                          " / $rentDuration",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        );
                      }),
                    ],
                  ),
                  if (ad.isHaveRoom)
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: "Building : "),
                          TextSpan(
                            text: "${ad.address["buildingName"]}, ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "Appartment number : "),
                          TextSpan(
                            text: "${ad.address["appartmentNumber"]}, ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "Floor number : "),
                          TextSpan(
                            text: "${ad.address["floorNumber"]}, ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    ad.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: controller._showAllDescription.isTrue ? null : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 20),
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: ROOMY_ORANGE,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Icon(Icons.person, color: ROOMY_ORANGE),
                        SizedBox(width: 5),
                        Text("ABOUT ME"),
                        Spacer(),
                      ],
                    ),
                  ),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            {
                              "label": "Age : ",
                              "value": '${ad.aboutYou["age"]} years',
                            },
                            {
                              "label": "Occupation : ",
                              "value": '${ad.aboutYou["occupation"]}',
                            },
                            {
                              "label": "Gender : ",
                              "value": '${ad.aboutYou["gender"]}',
                            },
                            {
                              "label": "Life style : ",
                              "value": '${ad.aboutYou["lifeStyle"]}',
                            },
                            {
                              "label": "Nationality : ",
                              "value": '${ad.aboutYou["nationality"]}',
                            },
                            {
                              "label": "Astrological sign : ",
                              "value": '${ad.aboutYou["astrologicalSign"]}',
                            },
                            {
                              "label": "Languages : ",
                              "value":
                                  (ad.aboutYou["languages"] as List).join(", "),
                            },
                          ].map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              width: Get.width - 20,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "   •   ${e["label"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: e["value"]),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  const Center(
                    child: Text(
                      "SHARING/HOUSING PREFERENCES",
                      style: TextStyle(
                        fontSize: 14,
                        color: ROOMY_ORANGE,
                      ),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    childAspectRatio: 1.5,
                    children: [
                      SocialPreferenceWidget(
                        icon: const Icon(Icons.group, color: ROOMY_ORANGE),
                        label: "People",
                        value: "${ad.socialPreferences["numberOfPeople"]}",
                      ),
                      SocialPreferenceWidget(
                        icon: const Icon(Icons.public, color: ROOMY_ORANGE),
                        label: "Nationality",
                        value: "${ad.socialPreferences["nationality"]}",
                      ),
                      SocialPreferenceWidget(
                        icon: Icon(
                            ad.socialPreferences["gender"] == "Male"
                                ? Icons.male
                                : Icons.female,
                            color: ROOMY_ORANGE),
                        label: "Gender",
                        value: "${ad.socialPreferences["gender"]}",
                      ),
                    ],
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    children: allSocialPreferences.map((e) {
                      return Card(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Expanded(
                                child: Image.asset("${e["asset"]}"),
                              ),
                              const SizedBox(width: 2),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${e["label"]}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Builder(builder: (context) {
                                    final isTrue = ad.socialPreferences
                                        .containsKey(e["value"]);
                                    return Text(
                                      isTrue ? 'Yes' : "No",
                                      style: TextStyle(
                                        color: Get.isDarkMode
                                            ? Colors.white
                                            : ROOMY_ORANGE,
                                        fontSize: 12,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 20),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Image.asset("assets/icons/washing_2.png",
                                    height: 30),
                                const Text("APPLIANCES"),
                              ],
                            ),
                            ...ad.homeAppliancesAmenities
                                .map((e) => Text("•  $e"))
                                .toList()
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Image.asset("assets/icons/wifi.png",
                                    height: 30),
                                const Text("TECH"),
                              ],
                            ),
                            ...ad.technologyAmenities
                                .map((e) =>
                                    Text("•  $e", textAlign: TextAlign.center))
                                .toList()
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.widgets, color: ROOMY_ORANGE),
                                Text("UTILITIES"),
                              ],
                            ),
                            ...ad.utilitiesAmenities
                                .map(
                                  (e) => Text("• $e", textAlign: TextAlign.end),
                                )
                                .toList()
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  const Center(
                    child: Text(
                      "INTERESTS",
                      style: TextStyle(
                        fontSize: 14,
                        color: ROOMY_ORANGE,
                      ),
                    ),
                  ),
                  if (ad.interests.isNotEmpty)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      childAspectRatio: 1.2,
                      children: roommateInterests
                          .where((e) => ad.interests.contains(e["value"]))
                          .map((e) {
                        return Card(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.asset("${e["asset"]}"),
                                ),
                                Text(
                                  "${e["value"]}",
                                  style: TextStyle(
                                    color: Get.isDarkMode
                                        ? Colors.white
                                        : ROOMY_ORANGE,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
