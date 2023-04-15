import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/components/amenities_widget.dart';
import 'package:roomy_finder/components/square_box_wrapper.dart';
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
    final conv = ChatConversation.newConversation(
      me: AppController.me.chatUser,
      friend: ad.poster.chatUser,
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 1),
              SquareBoxWrapper(
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CarouselSlider(
                              carouselController: controller.carouselController,
                              items: [
                                ...ad.images.map(
                                  (e) {
                                    return GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => ViewImages(
                                            images: ad.images
                                                .map((e) =>
                                                    CachedNetworkImageProvider(
                                                        e))
                                                .toList(),
                                            initialIndex: ad.images.indexOf(e),
                                          ),
                                          transition: Transition.zoom,
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 1),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(5),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: e,
                                            height: 250,
                                            width: Get.width,
                                            fit: BoxFit.cover,
                                            errorWidget: (ctx, e, trace) {
                                              return const SizedBox(
                                                child:
                                                    CupertinoActivityIndicator(
                                                  radius: 30,
                                                  animating: false,
                                                ),
                                              );
                                            },
                                            progressIndicatorBuilder: (context,
                                                url, downloadProgress) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child:
                                                    CircularProgressIndicator(
                                                  value:
                                                      downloadProgress.progress,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
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
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(5),
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
                                              future:
                                                  VideoThumbnail.thumbnailFile(
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
                              options: CarouselOptions(
                                autoPlayInterval: const Duration(seconds: 10),
                                pageSnapping: true,
                                autoPlay: true,
                                viewportFraction: 1,
                                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                                enableInfiniteScroll: false,
                              ),
                            ),
                            if (ad.images.length > 1)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          borderRadius:
                                              BorderRadius.circular(50),
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
                                          borderRadius:
                                              BorderRadius.circular(100),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 80, right: 5),
                          child: Row(
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    ad.action,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (!ad.isMine)
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
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 80, right: 5),
                          child: Divider(height: 2),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 80),
                          child: Row(
                            children: [
                              const Icon(Icons.room,
                                  color: ROOMY_ORANGE, size: 14),
                              Text(
                                "${ad.address["city"]}, ${ad.address["location"]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              Builder(builder: (context) {
                                // ignore: unused_local_variable
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
                                return Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: formatMoney(
                                        ad.budget *
                                            AppController.convertionRate,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ]),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 2,
                      child: GestureDetector(
                        onTap: () =>
                            controller._viewImage(ad.poster.profilePicture),
                        child: ad.poster.ppWidget(borderColor: false, size: 35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Description
              if (ad.description != null && ad.description!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: SquareBoxWrapper(
                    child: ReadMoreText(
                      ad.description!,
                      trimLines: 3,
                      trimCollapsedText: "Read more",
                      trimExpandedText: "Read less",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                      trimMode: TrimMode.Line,
                      colorClickableText: ROOMY_ORANGE,
                    ),
                  ),
                ),
              if (ad.description != null && ad.description!.isNotEmpty)
                const SizedBox(height: 20),
              // About me
              SquareBoxWrapper(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person, color: ROOMY_ORANGE),
                                SizedBox(width: 5),
                                Text("ABOUT ME"),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: const [
                                Icon(Icons.person_add_alt_1,
                                    color: ROOMY_ORANGE),
                                SizedBox(width: 5),
                                Text("PREFERRED ROOMMATE"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                {
                                  "label": "Age : ",
                                  "value": ad.aboutYou["age"] == null
                                      ? "N/A"
                                      : '${ad.aboutYou["age"]} years',
                                },
                                {
                                  "label": "Occupation : ",
                                  "value": ad.aboutYou["occupation"] ?? "N/A",
                                },
                                {
                                  "label": "Gender : ",
                                  "value": ad.aboutYou["gender"] ?? "N/A",
                                },
                                {
                                  "label": "Life style : ",
                                  "value": ad.aboutYou["lifeStyle"] ?? "N/A",
                                },
                                {
                                  "label": "Nationality : ",
                                  "value": ad.aboutYou["nationality"] ?? "N/A",
                                },
                                {
                                  "label": "Astrological sign : ",
                                  "value":
                                      ad.aboutYou["astrologicalSign"] ?? "N/A",
                                },
                              ].map((e) {
                                return Container(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  // width: Get.width - 20,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "•      ${e["label"]}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: "${e["value"]}"),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                {
                                  "label": "Gender : ",
                                  "value":
                                      ad.socialPreferences["gender"] ?? "N/A",
                                },
                                {
                                  "label": "Nationality : ",
                                  "value":
                                      ad.socialPreferences["nationality"] ??
                                          "N/A",
                                },
                                {
                                  "label": "Life style : ",
                                  "value": ad.aboutYou["lifeStyle"] ?? "N/A",
                                },
                              ].map((e) {
                                return Container(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  // width: Get.width - 20,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "•      ${e["label"]}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: "${e["value"]}"),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DefaultTextStyle.merge(
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 10),
                          const Text(
                            "•      Languages : ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Builder(builder: (context) {
                            final data = List<String>.from(
                                ad.aboutYou["languages"] as List);
                            if (data.isEmpty) return const Text("N/A");
                            return Text(
                              data.reduce((val, e) {
                                if (data.indexOf(e).remainder(2) == 0) {
                                  return "$val\n$e";
                                }
                                return "$val, $e";
                              }),
                              style: const TextStyle(),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Preferrence
              SquareBoxWrapper(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        ad.isHaveRoom
                            ? "SHARING/HOUSING PREFERENCES"
                            : "HOUSING PREFERENCES",
                        style: const TextStyle(
                          fontSize: 14,
                          color: ROOMY_ORANGE,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        allSocialPreferences[0],
                        allSocialPreferences[1],
                        allSocialPreferences[2],
                      ].map(
                        (e) {
                          return _PreferenceItem(
                            height: 60,
                            width: Get.width * 0.27,
                            iconPath: "${e["asset"]}",
                            label: "${e["label"]}",
                            value: ad.socialPreferences["${e["value"]}"] == true
                                ? "Yes"
                                : "No",
                            color: ad.socialPreferences["${e["value"]}"] == true
                                ? Colors.green
                                : Colors.red,
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        allSocialPreferences[3],
                        allSocialPreferences[4],
                      ].map(
                        (e) {
                          return _PreferenceItem(
                            height: 60,
                            width: Get.width * 0.27,
                            iconPath: "${e["asset"]}",
                            label: "${e["label"]}",
                            value: ad.socialPreferences["${e["value"]}"] == true
                                ? "Yes"
                                : "No",
                            color: ad.socialPreferences["${e["value"]}"] == true
                                ? Colors.green
                                : Colors.red,
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amenities
              SquareBoxWrapper(
                child: AmenitiesWidget(ad: ad, labelSuffix: "•"),
              ),
              const SizedBox(height: 20),

              // Interest
              SquareBoxWrapper(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Text(
                        "INTERESTS",
                        style: TextStyle(
                          fontSize: 14,
                          color: ROOMY_ORANGE,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (ad.interests.isNotEmpty)
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
                                  child: Image.asset("${e["asset"]}"),
                                ),
                                Text(
                                  "${e["value"]}",
                                  style: TextStyle(
                                    color: Get.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  const _PreferenceItem({
    required this.iconPath,
    required this.label,
    required this.value,
    this.color,
    required this.height,
    required this.width,
  });

  final String iconPath;
  final String label;
  final String value;
  final Color? color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: shadowedBoxDecoration,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: Image.asset(iconPath),
          ),
          const SizedBox(width: 2),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10)),
              Text(value, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
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
