import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:readmore/readmore.dart';
import 'package:roomy_finder/helpers/favorite_helper.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:roomy_finder/functions/share_ad.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/booking/booking_confirmation.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';

class _VewPropertyController extends LoadingController {
  _VewPropertyController(this.ad);
  String? bookingId;

  final PropertyAd ad;

  // Caroussel
  final CarouselController carouselController = CarouselController();
  int _currentCarousselIndex = 0;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;

  // Favorite
  bool _isInFavorites = false;
  Future<void> _addToFavovites() async {
    await FovoritePropertyAdHelper.addToFavorites(ad);
    _isInFavorites = true;
    showToast("Added to favorites");
    update();
  }

  Future<void> _removeFromFavovites() async {
    await FovoritePropertyAdHelper.removeFromFavorites(ad.id);
    _isInFavorites = false;
    showToast("Removed to favorites");
    update();
  }

  @override
  onInit() {
    super.onInit();

    FovoritePropertyAdHelper.isInFovarite(ad.id).then((value) {
      _isInFavorites = value;
      update();
    });

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        final newAd = await ApiService.fetchPropertyAd(ad.id);

        if (newAd != null) {
          ad.updateFrom(newAd);

          update();
        }
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      for (var img in ad.images) {
        precacheImage(CachedNetworkImageProvider(img), Get.context!);
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _fGBGNotifierSubScription.cancel();
  }

  Future<void> editAd() async {
    Get.to(() => PostPropertyAdScreen(oldData: ad));
  }

  Future<void> deleteAd() async {
    final shouldContinue = await showConfirmDialog(
      "Please confirm",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);
      final res = await ApiService.getDio.delete("/ads/property-ad/${ad.id}");

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
      } else if (res.statusCode == 400) {
        isLoading(false);
        final message = res.data["code"] == "is-booked"
            ? "This ad is booked. You must decline all "
                "the bookings releted to this ad before deleting it"
            : "There is a deal on this ad. You must end all the deals "
                "releted to this ad before deleting it";

        await showConfirmDialog(message, isAlert: true);
      } else {
        showToast(
          "Failed to book ad. Please try again",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log("$e");
      showToast(
        "Failed to book ad. Please try again",
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> cancelBooking() async {
    final shouldContinue = await showConfirmDialog(
      "Please confirm",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);

      final res = await ApiService.getDio.post(
        "/bookings/property-ad/tenant/cancel",
        data: {'bookingId': bookingId},
      );

      if (res.statusCode == 200) {
        bookingId = null;
        isLoading(false);
        update();

        await showConfirmDialog(
          "Booking cancelled",
          isAlert: true,
        );
      } else {
        showToast(
          "Failed to cancel booking. Please try again",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log("$e");
      showToast(
        "Failed to cancel booking. Please try again",
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
    }
  }

  // Future<void> enableAutoBookingApproval() async {
  //   final paymentMethod = await showDialog(
  //     context: Get.context!,
  //     builder: (context) {
  //       return CupertinoAlertDialog(
  //         title: const Text("Auto Approval"),
  //         content: const Text.rich(
  //           TextSpan(children: [
  //             TextSpan(
  //               text: "Auto Approval with permit your property bookings to be"
  //                   " automaticaly approved. You need to pay ",
  //             ),
  //             TextSpan(
  //               text: "250 AED",
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             TextSpan(text: " for a "),
  //             TextSpan(
  //               text: "One Month Activation",
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             TextSpan(text: ". Please select a payment method."),
  //           ]),
  //         ),
  //         actions: [
  //           CupertinoDialogAction(
  //             child: const Text("STRIPE"),
  //             onPressed: () => Get.back(result: "STRIPE"),
  //           ),
  //           CupertinoDialogAction(
  //             child: const Text("PAYPAL"),
  //             onPressed: () => Get.back(result: "PAYPAL"),
  //           ),
  //           CupertinoDialogAction(
  //             child: const Text("CANCEL"),
  //             onPressed: () => Get.back(),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (paymentMethod == null) return;

  //   try {
  //     isLoading(true);

  //     final res = await ApiService.getDio.post(
  //       "/ads/property-ad/${ad.id}/pay-auto-approval",
  //       data: {'months': 1, "paymentMethod": paymentMethod},
  //     );

  //     if (res.statusCode == 503) {
  //       showToast("$paymentMethod service temporally unavailable");
  //       return;
  //     } else if (res.statusCode == 200) {
  //       showToast("Payment initiated. Redirecting....");

  //       final uri = Uri.parse(res.data["paymentUrl"]);

  //       if (await canLaunchUrl(uri)) {
  //         launchUrl(uri, mode: LaunchMode.externalApplication);
  //       } else {
  //         showToast("Failed to open payment link. Please install a browser");
  //       }
  //     } else {
  //       showToast(
  //         "Operation. Please try again",
  //         severity: Severity.error,
  //       );
  //     }
  //   } catch (e) {
  //     Get.log("$e");
  //     showToast(
  //       "Operation failed. Please try again",
  //       severity: Severity.error,
  //     );
  //   } finally {
  //     isLoading(false);
  //   }
  // }

  Future<void> toggleAutoApproval() async {
    String message;
    final iso = ad.autoApproval!["expireAt"].toString();

    if (ad.autoApprovalIsEnabled) {
      message = "Auto approval is enabled and it expires on "
          "${Jiffy.parse(iso).yMMMEd}. Do you want to disable?";
    } else {
      message = "Auto approval is disabled and it expires on "
          "${Jiffy.parse(iso).yMMMEd}. Do you want to enable?";
    }
    try {
      final confirm = await showConfirmDialog(message, title: "Auto Approval");

      if (confirm != true) return;

      isLoading(true);

      final res = await ApiService.getDio.post(
        "/ads/property-ad/${ad.id}/toggle-auto-approval",
      );

      if (res.statusCode == 200) {
        String status;

        if (res.data["enabled"] == true) {
          status = "enabled";
        } else {
          status = "disabled";
        }

        if (res.data != null) {
          ad.autoApproval = Map<String, Object>.from(res.data);
        }

        showToast("Auto approval $status successfully");
      } else {
        showToast("Operation failed. please try again");
      }
    } catch (e) {
      Get.log("$e");
      showToast("Operation failed. please try again");
    } finally {
      isLoading(false);

      update(["auto-approval"]);
    }
  }
}

class ViewPropertyAd extends StatelessWidget {
  const ViewPropertyAd({super.key, required this.ad, this.readOnly = false});

  final PropertyAd ad;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    Get.put(_VewPropertyController(ad));

    int crossAxisCount = MediaQuery.sizeOf(context).width ~/ 90;

    return GetBuilder<_VewPropertyController>(builder: (controller) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          title: Text("${ad.type} Property"),
          backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
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
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
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
                              "assets/images/default_room.png",
                              height: 250,
                              width: Get.width,
                              fit: BoxFit.cover,
                            ),
                          ...ad.images.map(
                            (e) => GestureDetector(
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
                            ),
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

                      GetBuilder<_VewPropertyController>(
                        id: "caroussel-marker",
                        builder: (controller) {
                          return Positioned(
                            bottom: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  ad.images.length + ad.videos.length, (ind) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        // Price & Prefered rent type
                        Builder(builder: (context) {
                          final String rentDuration;
                          switch (ad.preferedRentType) {
                            case "Monthly":
                              rentDuration = "month";
                              break;
                            case "Weekly":
                              rentDuration = "week";
                              break;
                            default:
                              rentDuration = "day";
                          }

                          final price = formatMoney(
                            ad.prefferedRentDisplayPrice *
                                AppController.convertionRate,
                          ).replaceFirst(
                            AppController.instance.country.value.currencyCode,
                            " ",
                          );

                          return Text.rich(
                            TextSpan(children: [
                              TextSpan(text: price),
                              const TextSpan(
                                text: "AED",
                                style: TextStyle(fontSize: 12),
                              ),
                              TextSpan(text: " / $rentDuration"),
                            ]),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          );
                        }),

                        // // Room type & quantity
                        // Row(
                        //   children: [
                        //     Text(
                        //       ad.type,
                        //       style: const TextStyle(fontWeight: FontWeight.bold),
                        //     ),
                        //     const Spacer(),
                        //     Text.rich(
                        //       TextSpan(
                        //         children: [
                        //           TextSpan(
                        //             text:
                        //                 "Available ${ad.quantity - ad.quantityTaken}",
                        //             style: const TextStyle(color: Colors.green),
                        //           ),
                        //           TextSpan(
                        //             text: " Taken ${ad.quantityTaken}",
                        //             style: const TextStyle(color: Colors.red),
                        //           ),
                        //         ],
                        //       ),
                        //       style: const TextStyle(fontSize: 12),
                        //     ),
                        //   ],
                        // ),
                        // Location
                        Text(
                          "${ad.location}, ${ad.buildingName}, ${ad.floorNumber}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

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
                                      "Area:",
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
                                      AssetIcons.doorPNG,
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
                                      AssetIcons.smallBedPNG,
                                      height: 30,
                                      color: Colors.grey,
                                    ),
                                    const Text(
                                      "Unit:",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "Available ${ad.quantity - ad.quantityTaken}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 20),

                        // Room overview
                        const Text(
                          "Room Overview",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),

                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              {
                                "label": "People",
                                "asset": "assets/icons/person.png",
                                "value":
                                    "${ad.socialPreferences["numberOfPeople"]}",
                              },
                              {
                                "label": "Nationality",
                                "asset": "assets/icons/globe.png",
                                "value":
                                    "${ad.socialPreferences["nationality"]}",
                              },
                              {
                                "label": "Gender",
                                "asset": "assets/icons/gender.png",
                                "value": ad.socialPreferences["gender"],
                              },
                              {
                                "label": "Smoking",
                                "asset": "assets/icons/smoking.png",
                                "value": ad.socialPreferences["smoking"] == true
                                    ? "Allowed"
                                    : "Not Allowed",
                              },
                              {
                                "label": "Visitors",
                                "asset": "assets/icons/people.png",
                                "value":
                                    ad.socialPreferences["visitors"] == true
                                        ? "Allowed"
                                        : "Not Allowed",
                              },
                              {
                                "label": "Drinking",
                                "asset": "assets/icons/drink.png",
                                "value":
                                    ad.socialPreferences["drinking"] == true
                                        ? "Allowed"
                                        : "Not Allowed",
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

                        // Amenities
                        const Text(
                          "Amenities",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            // fontWeight: FontWeight.bold,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
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

                        const Divider(height: 20),

                        // Booking
                        const Text(
                          "Booking details",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),

                        DefaultTextStyle.merge(
                          style: const TextStyle(color: Colors.black54),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  "Price",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Monthly"),
                                    Text("Weekly"),
                                    Text("Daily"),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Builder(builder: (context) {
                                  var convertionRate =
                                      AppController.convertionRate;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (ad.monthlyPrice != null)
                                        formatMoney(
                                          (ad.monthlyPrice! +
                                                  ad.monthlyCommission!) *
                                              convertionRate,
                                        )
                                      else
                                        "N/A",
                                      if (ad.weeklyPrice != null)
                                        formatMoney(
                                          (ad.weeklyPrice! +
                                                  ad.weeklyCommission!) *
                                              convertionRate,
                                        )
                                      else
                                        "N/A",
                                      if (ad.dailyPrice != null)
                                        formatMoney(
                                          (ad.dailyPrice! +
                                                  ad.dailyCommission!) *
                                              AppController.convertionRate,
                                        )
                                      else
                                        "N/A",
                                    ].map((e) => Text(e)).toList(),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        DefaultTextStyle.merge(
                          style: const TextStyle(color: Colors.black54),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  "Deposit",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                  child: Text(ad.hasDeposit ? "Yes" : "No")),
                              Expanded(
                                child: Text(
                                  ad.hasDeposit
                                      ? formatMoney((ad.depositPrice!) *
                                          AppController.convertionRate)
                                      : "N/A",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Location",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${ad.buildingName}, ${ad.location}, ${ad.city}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Image.asset("assets/images/map.jpg"),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!ad.isMine) const SizedBox(height: 50),
                ],
              ),
            ),
            if (controller.isLoading.isTrue) const LoadingPlaceholder(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: (!ad.isMine && !readOnly)
            ? GetBuilder<_VewPropertyController>(builder: (controller) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 3,
                        blurStyle: BlurStyle.outer,
                        color: Colors.black54,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ROOMY_ORANGE,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      side: const BorderSide(color: ROOMY_ORANGE),
                    ),
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : () {
                            if (controller.bookingId != null) {
                              controller.cancelBooking();
                            } else {
                              Get.to(() {
                                return BookingConfirmationScreen(ad: ad);
                              });
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.bookingId != null
                              ? "Cancel booking"
                              : "Book this room",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_double_arrow_right,
                          color: Colors.white,
                          weight: 10,
                        )
                      ],
                    ),
                  ),
                );
              })
            : null,
      );
    });
  }
}
