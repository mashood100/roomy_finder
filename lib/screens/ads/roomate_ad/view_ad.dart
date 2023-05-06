import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
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
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class _ViewRoommateAdController extends LoadingController {
  final RoommateAd ad;

  _ViewRoommateAdController(this.ad);

  // Caroussel
  final CarouselController carouselController = CarouselController();
  int _currentCarousselIndex = 0;

  Future<void> editAd() async {
    Get.to(() => PostRoommateAdScreen(oldData: ad));
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
    final conv = ChatConversation(other: ad.poster.chatUser);
    Get.to(
      () => FlyerChatScreen(
        conversation: conv,
        myId: AppController.me.id,
        otherId: ad.poster.id,
      ),
    );
  }

  void _viewImage(String source) {
    Get.to(
      () => ViewImages(images: [CachedNetworkImageProvider(source)]),
      transition: Transition.zoom,
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
        title: const Text(
          "View Roommate ad",
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: ROOMY_PURPLE,
        actions: [
          if (!AppController.me.isGuest)
            IconButton(
              onPressed: () async {
                await addAdToFavorite(ad.toJson(), "favorites-roommates-ads");
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
            Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Caroussel
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CarouselSlider(
                          carouselController: controller.carouselController,
                          items: [
                            if (ad.images.isEmpty && ad.videos.isEmpty)
                              Image.asset(
                                "assets/images/default_roommate.jpg",
                                height: 250,
                                width: Get.width,
                                fit: BoxFit.cover,
                              ),
                            ...ad.images.map(
                              (e) {
                                return GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => ViewImages(
                                        images: ad.images
                                            .map((e) =>
                                                CachedNetworkImageProvider(e))
                                            .toList(),
                                        initialIndex: ad.images.indexOf(e),
                                      ),
                                      transition: Transition.zoom,
                                    );
                                  },
                                  child: CachedNetworkImage(
                                    imageUrl: e,
                                    height: 250,
                                    width: Get.width,
                                    fit: BoxFit.cover,
                                    errorWidget: (ctx, e, trace) {
                                      return const SizedBox(
                                        child: CupertinoActivityIndicator(
                                          radius: 30,
                                          animating: false,
                                        ),
                                      );
                                    },
                                    progressIndicatorBuilder:
                                        (context, url, downloadProgress) {
                                      return Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: CircularProgressIndicator(
                                          value: downloadProgress.progress,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            ...ad.videos.map(
                              (e) => GestureDetector(
                                onTap: () => Get.to(() {
                                  return PlayVideoScreen(
                                      source: e, isAsset: false);
                                }),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    FutureBuilder(
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
                          options: CarouselOptions(
                            autoPlayInterval: const Duration(seconds: 10),
                            pageSnapping: true,
                            autoPlay: true,
                            viewportFraction: 1,
                            enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                            enableInfiniteScroll: false,
                            onPageChanged: (index, reason) {
                              controller._currentCarousselIndex = index;
                              controller.update(["caroussel-marker"]);
                            },
                          ),
                        ),
                        // Next/Previous buttons
                        if (ad.images.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  controller.carouselController.previousPage();
                                },
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  controller.carouselController.nextPage();
                                },
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                        // Index indicator
                        GetBuilder<_ViewRoommateAdController>(
                          id: "caroussel-marker",
                          builder: (controller) {
                            return Positioned(
                              bottom: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  ad.images.length + ad.videos.length,
                                  (ind) => Icon(
                                    controller._currentCarousselIndex == ind
                                        ? Icons.circle
                                        : Icons.circle_outlined,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Edit / Delete icons buttons
                        if (ad.isMine)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    // side: const BorderSide(color: Colors.green),
                                  ),
                                  onPressed: controller.isLoading.isTrue
                                      ? null
                                      : controller.editAd,
                                  icon: Image.asset(
                                    "assets/icons/edit.png",
                                    height: 30,
                                    width: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    // side: const BorderSide(color: Colors.red),
                                  ),
                                  onPressed: controller.isLoading.isTrue
                                      ? null
                                      : controller.deleteAd,
                                  icon: Image.asset(
                                    "assets/icons/delete.png",
                                    height: 30,
                                    width: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 10),
                    // User & location information
                    Padding(
                      padding: const EdgeInsets.only(left: 100, right: 10),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ad.poster.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              // Action : HAVE ROOM / NEED ROOM
                              Text(
                                ad.action,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 10),
                              // Location
                              Text(
                                "${ad.address["buildingName"] ?? "N/A"},"
                                " ${ad.address["location"]},"
                                " ${ad.address["city"]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (!ad.isMine)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ROOMY_ORANGE,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      side:
                                          const BorderSide(color: ROOMY_ORANGE),
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
                                ),
                                const SizedBox(height: 20),
                                Builder(builder: (context) {
                                  final price = formatMoney(
                                    ad.budget * AppController.convertionRate,
                                  ).replaceFirst(
                                    AppController
                                        .instance.country.value.currencyCode,
                                    "",
                                  );

                                  return Text.rich(
                                    TextSpan(children: [
                                      TextSpan(text: price),
                                      TextSpan(
                                        text: AppController.instance.country
                                            .value.currencyCode,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      const TextSpan(
                                        text: " \nBudget",
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ]),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 25,
                  left: 5,
                  child: GestureDetector(
                    onTap: () {
                      if (ad.poster.profilePicture == null) return;

                      controller._viewImage(ad.poster.profilePicture!);
                    },
                    child: ad.poster.ppWidget(borderColor: false, size: 45),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 20),

                  // Description

                  if (ad.description != null && ad.description!.isNotEmpty) ...[
                    ReadMoreText(
                      ad.description!,
                      trimLines: 3,
                      trimCollapsedText: "Read more",
                      trimExpandedText: "Read less",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                      trimMode: TrimMode.Line,
                      colorClickableText: ROOMY_PURPLE,
                    ),
                    const Divider(height: 20),
                  ],

                  // About me
                  const Text(
                    "About me",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      children: [
                        {
                          "label": "Age",
                          "asset": "assets/icons/person.png",
                          "value": ad.aboutYou["age"] ?? "N/A",
                        },
                        {
                          "label": "Occupation",
                          "asset": "assets/icons/occupation.png",
                          "value": ad.aboutYou["occupation"] ?? "N/A",
                        },
                        {
                          "label": "Sign",
                          "asset": "assets/icons/astrological_sign.png",
                          "value": ad.aboutYou["astrologicalSign"] ?? "N/A",
                        },
                        {
                          "label": "Gender",
                          "asset": "assets/icons/gender.png",
                          "value": ad.aboutYou["gender"] ?? "N/A",
                        },
                        {
                          "label": "Nationality",
                          "asset": "assets/icons/globe.png",
                          "value": ad.poster.country,
                        },
                        {
                          "label": "Lifestyle",
                          "asset": "assets/icons/lifestyle.png",
                          "value": ad.socialPreferences["lifestyle"] ?? "N/A",
                        },
                      ].map((e) {
                        return AdOverViewItem(
                          title: Text("${e["label"]}"),
                          subTitle: Text(
                            "${e["value"]}",
                            style: const TextStyle(fontSize: 10),
                          ),
                          icon: Image.asset(
                            e["asset"].toString(),
                            height: 30,
                            width: 30,
                            color: Colors.black54,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        "assets/icons/language.png",
                        height: 30,
                        width: 30,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Languages",
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                          Builder(
                            builder: (context) {
                              final data = List<String>.from(
                                  ad.aboutYou["languages"] as List);

                              for (int i = 0; i < data.length; i++) {
                                var e = data[i];
                                if (i == data.length - 1) break;
                                if (i.isEven) {
                                  data[i] = "$e, ";
                                } else {
                                  data[i] = "$e,\n";
                                }
                              }

                              return Text(
                                data.isNotEmpty ? data.join('') : "N/A",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Preference
                  const Text(
                    "Preffered roommate",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 5),

                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                    child: Row(
                      children: [
                        {
                          "label": "Gender",
                          "asset": "assets/icons/gender.png",
                          "value": ad.socialPreferences["gender"] ?? "N/A",
                        },
                        {
                          "label": "Nationality",
                          "asset": "assets/icons/globe.png",
                          "value": ad.socialPreferences["nationality"] ?? "N/A",
                        },
                        {
                          "label": "Lifestyle",
                          "asset": "assets/icons/lifestyle.png",
                          "value": ad.socialPreferences["lifestyle"] ?? "N/A",
                        },
                      ].map((e) {
                        return SizedBox(
                          width: (Get.width - 20) / 3,
                          child: AdOverViewItem(
                            title: Text("${e["label"]}"),
                            subTitle: Text("${e["value"]}"),
                            icon: Image.asset(
                              e["asset"].toString(),
                              height: 30,
                              width: 30,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(height: 20),

                  //Housing Preference
                  Text(
                    ad.isHaveRoom
                        ? "Sharing/Housing Preference"
                        : "Housing Preferences",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisSpacing: 20,
                      children: [
                        {
                          "label": "Pets",
                          "asset": "assets/icons/pet.png",
                          "value": ad.socialPreferences["pet"] == true
                              ? "Yes"
                              : "No",
                        },
                        {
                          "label": "Smoking",
                          "asset": "assets/icons/smoking.png",
                          "value": ad.socialPreferences["smoking"] == true
                              ? "Yes"
                              : "No",
                        },
                        {
                          "label": "Party",
                          "asset": "assets/icons/party.png",
                          "value": ad.socialPreferences["friendParty"] == true
                              ? "Yes"
                              : "No",
                        },
                        {
                          "label": "Drinking",
                          "asset": "assets/icons/drink.png",
                          "value": ad.socialPreferences["drinking"] == true
                              ? "Yes"
                              : "No",
                        },
                        {
                          "label": "Visitors",
                          "asset": "assets/icons/people.png",
                          "value": ad.socialPreferences["visitors"] == true
                              ? "Yes"
                              : "No",
                        },
                      ].map((e) {
                        return AdOverViewItem(
                          title: Text("${e["label"]}"),
                          subTitle: Text("${e["value"]}"),
                          subTitleColor:
                              e["value"] == "Yes" ? Colors.green : Colors.red,
                          icon: Image.asset(
                            e["asset"].toString(),
                            height: 30,
                            width: 30,
                            color: Colors.black54,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Divider(height: 20),

                  // Amenities
                  const Text(
                    "Amenities",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      children: allAmenities
                          .where((e) => ad.amenities.contains(e["value"]))
                          .map((e) {
                        return AdOverViewItem(
                          title: Text("${e["value"]}"),
                          icon: Image.asset(
                            e["asset"].toString(),
                            height: 30,
                            width: 30,
                            color: Colors.black54,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(height: 20),

                  // Interests
                  const Text(
                    "Interests",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: roommateInterests
                        .where((e) => ad.interests.contains(e["value"]))
                        .map((e) {
                      return Container(
                        decoration: shadowedBoxDecoration,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.asset(
                                "${e["asset"]}",
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "${e["value"]}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
