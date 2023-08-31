import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:readmore/readmore.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/share_ad.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/favorite_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
// import 'package:roomy_finder/screens/new_chat/chat_room.dart';
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

  // Favorite
  bool _isInFavorites = false;
  Future<void> _addToFavovites() async {
    await FovoriteRoommateAdHelper.addToFavorites(ad);
    _isInFavorites = true;
    showToast("Added to favorites");
    update();
  }

  Future<void> _removeFromFavovites() async {
    await FovoriteRoommateAdHelper.removeFromFavorites(ad.id);
    _isInFavorites = false;
    showToast("Removed to favorites");
    update();
  }

  @override
  void onInit() {
    FovoriteRoommateAdHelper.isInFovarite(ad.id).then((value) {
      _isInFavorites = value;
      update();
    });
    super.onInit();
  }

  Future<void> editAd() async {
    Get.to(() => PostRoommateAdScreen(
          oldData: ad,
          action: ad.action,
        ));
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
        await showConfirmDialog("Ad deleted successfully.", isAlert: true);
        Get.back(result: {"deletedId": ad.id});

        deleteManyFilesFromUrl(ad.images);
        deleteManyFilesFromUrl(ad.videos);
      } else if (res.statusCode == 404) {
        isLoading(false);
        await showConfirmDialog(
          "Ad not found. It may have been deleted alredy",
          isAlert: true,
        );
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
    if (AppController.me.isGuest) {
      RoomyNotificationHelper.showRegistrationRequiredToChat();
    } else {
      moveToChatRoom(AppController.me, ad.poster);
    }
  }

  void _viewImage(String source) {
    Get.to(
      () => ViewImages(images: [CachedNetworkImageProvider(source)]),
      transition: Transition.zoom,
    );
  }
}

class ViewRoommateAdScreen extends StatelessWidget {
  const ViewRoommateAdScreen(
      {super.key, required this.ad, this.readOnly = false});

  final RoommateAd ad;
  final bool readOnly;

  bool get _isHaveRoom => ad.action == "HAVE ROOM";

  @override
  Widget build(BuildContext context) {
    Get.put(_ViewRoommateAdController(ad));

    int crossAxisCount = MediaQuery.sizeOf(context).width ~/ 90;

    return GetBuilder<_ViewRoommateAdController>(builder: (controller) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          title: Text(
            ad.action,
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: ROOMY_PURPLE,
          actions: [
            if (!AppController.me.isGuest)
              IconButton(
                onPressed: controller._isInFavorites
                    ? controller._removeFromFavovites
                    : controller._addToFavovites,
                icon: controller._isInFavorites
                    ? const Icon(CupertinoIcons.heart_fill, color: ROOMY_ORANGE)
                    : const Icon(CupertinoIcons.heart),
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
                                  AssetImages.defaultRoomPNG,
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
                                    child: LoadingProgressImage(
                                      image: CachedNetworkImageProvider(e),
                                      height: 250,
                                      width: Get.width,
                                      fit: BoxFit.cover,
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
                              autoPlayInterval: const Duration(seconds: 20),
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
                                    controller.carouselController
                                        .previousPage();
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
                                      (ind) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      child: Icon(
                                        controller._currentCarousselIndex == ind
                                            ? Icons.circle
                                            : Icons.circle_outlined,
                                        size: 8,
                                        color: Colors.white,
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // User & location information
                      Padding(
                        padding: const EdgeInsets.only(left: 110, right: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ad.poster.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (!ad.isMine && !readOnly)
                              CustomButton(
                                "   Chat   ",
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : controller.chatWithUser,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Action buttons
                  Positioned(
                    top: 5,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      child: Row(
                        children: [
                          (
                            onPressed: () => Get.back(),
                            icon: const Icon(CupertinoIcons.back),
                          ),
                          null,
                          (
                            onPressed: () => shareAd(ad),
                            icon: const Icon(CupertinoIcons.share),
                          ),
                          (
                            onPressed: controller._isInFavorites
                                ? controller._removeFromFavovites
                                : controller._addToFavovites,
                            icon: controller._isInFavorites
                                ? const Icon(CupertinoIcons.heart_fill,
                                    color: ROOMY_ORANGE)
                                : const Icon(CupertinoIcons.heart),
                          ),
                          if (ad.isMine && !readOnly)
                            (
                              onPressed: () => controller.editAd(),
                              icon: const Icon(CupertinoIcons.pen),
                            ),
                          if (ad.isMine && !readOnly)
                            (
                              onPressed: () => controller.deleteAd(),
                              icon: const Icon(CupertinoIcons.delete,
                                  color: Colors.red),
                            ),
                        ].map((e) {
                          if (e == null) return const Spacer();

                          return IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: e.onPressed,
                            icon: e.icon,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Profile picture
                  Positioned(
                    bottom: 20,
                    left: 10,
                    child: GestureDetector(
                      onTap: () {
                        if (ad.poster.profilePicture == null) return;

                        controller._viewImage(ad.poster.profilePicture!);
                      },
                      child: ad.poster.ppWidget(borderColor: false, size: 40),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 20),

                    // Description

                    if (ad.description != null &&
                        ad.description!.isNotEmpty) ...[
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

                    DefaultTextStyle.merge(
                      style: const TextStyle(color: Colors.black87),
                      child: Row(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  AssetIcons.locationPNG,
                                  height: 30,
                                  color: Colors.grey,
                                ),
                                const Text(
                                  "Location:",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  ad.location,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            alignment: Alignment.center,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  AssetIcons.bigBed1PNG,
                                  height: 30,
                                  color: Colors.grey,
                                ),
                                const Text(
                                  "Room Type:",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  ad.type,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            alignment: Alignment.center,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  AssetIcons.dollarPNG,
                                  height: 30,
                                  color: Colors.grey,
                                ),
                                const Text(
                                  "Budget:",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "${formatMoney(ad.budget)}\n${ad.rentType}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (ad.isNeedRoom) ...[
                            Container(
                              width: 2,
                              height: 40,
                              alignment: Alignment.center,
                              color: Colors.grey.withOpacity(0.6),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    AssetIcons.calenderPNG,
                                    height: 30,
                                    color: Colors.grey,
                                  ),
                                  const Text(
                                    "Move date:",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    Jiffy.parseFromDateTime(ad.createdAt)
                                        .toLocal()
                                        .yMMMd,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),

                    const Divider(height: 20),

                    Text(
                      _isHaveRoom ? "About me" : "About me",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          {
                            "label": "Age",
                            "asset": AssetIcons.personPNG,
                            "value": ad.aboutYou["age"] ?? "N/A",
                          },
                          {
                            "label": "Languages",
                            "asset": AssetIcons.languagePNG,
                            "value": List<String>.from(
                                    ad.aboutYou["languages"] as List)
                                .join(", "),
                          },
                          {
                            "label": "Gender",
                            "asset": AssetIcons.genderPNG,
                            "value": ad.aboutYou["gender"] ?? "N/A",
                          },
                          {
                            "label": "Nationality",
                            "asset": AssetIcons.globePNG,
                            "value": ad.aboutYou["nationality"] ?? "N/A",
                          },
                          {
                            "label": "Occupation",
                            "asset": AssetIcons.occupationPNG,
                            "value": ad.aboutYou["occupation"] ?? "N/A",
                          },
                          {
                            "label": "Lifestyle",
                            "asset": AssetIcons.lifestylePNG,
                            "value": ad.aboutYou["lifeStyle"] ?? "N/A",
                          },
                          {
                            "label": "Sign",
                            "asset": AssetIcons.astrologicalSignPNG,
                            "value": ad.aboutYou["astrologicalSign"] ?? "N/A",
                          },
                        ].map((e) {
                          return Label(
                            label: "${e["label"]} :",
                            value: "${e["value"]}",
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: ROOMMATE_INTERESTS
                          .where((e) => ad.interests.contains(e["value"]))
                          .map((e) {
                        return Container(
                          decoration: shadowedBoxDecoration,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Image.asset(
                                  "${e["asset"]}",
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    "${e["value"]}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const Divider(height: 20),

                    // Preference
                    const Text(
                      "Preffered roommate",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          {
                            "label": "Gender",
                            "asset": AssetIcons.genderPNG,
                            "value": ad.socialPreferences["gender"] ?? "N/A",
                          },
                          {
                            "label": "Nationality",
                            "asset": AssetIcons.globePNG,
                            "value":
                                ad.socialPreferences["nationality"] ?? "N/A",
                          },
                          {
                            "label": "Lifestyle",
                            "asset": AssetIcons.lifestylePNG,
                            "value": ad.socialPreferences["lifeStyle"] ?? "N/A",
                          },
                        ].map((e) {
                          return Label(
                            label: "${e["label"]} :",
                            value: "${e["value"]}",
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

                    const Divider(height: 30),

                    //Housing Preference
                    Text(
                      ad.isNeedRoom
                          ? "Sharing/Housing Preference"
                          : "Housing Preferences",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          {
                            "label": "Pets",
                            "asset": "assets/icons/pet.png",
                            "value": ad.socialPreferences["pet"] == true
                          },
                          {
                            "label": "Visitors",
                            "asset": "assets/icons/people.png",
                            "value": ad.socialPreferences["visitors"] == true
                          },
                          {
                            "label": "Smoking",
                            "asset": "assets/icons/smoking.png",
                            "value": ad.socialPreferences["smoking"] == true
                          },
                          {
                            "label": "Party",
                            "asset": "assets/icons/party.png",
                            "value": ad.socialPreferences["friendParty"] == true
                          },
                          {
                            "label": "Drinking",
                            "asset": "assets/icons/drink.png",
                            "value": ad.socialPreferences["drinking"] == true
                          },
                        ].map((e) {
                          final String value;

                          if (_isHaveRoom) {
                            if (e["value"] == true) {
                              value = "Allowed";
                            } else {
                              value = "Not Allowed";
                            }
                          } else {
                            if (e["value"] == true) {
                              value = "Comfortable";
                            } else {
                              value = "Uncomfortable";
                            }
                          }

                          return Label(
                            label: "${e["label"]} :",
                            value: value,
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

                    // Amenities
                    Text(
                      _isHaveRoom ? "Amenities" : "Preferred amenities",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: ALL_AMENITIES
                            .where((e) => ad.amenities.contains(e["value"]))
                            .map((e) {
                          return Container(
                            decoration: shadowedBoxDecoration,
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Image.asset(
                                    "${e["asset"]}",
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      child: Text(
                                        "${e["value"]}",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
