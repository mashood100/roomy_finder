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
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/share_ad.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class _VewPropertyController extends LoadingController {
  _VewPropertyController(this.ad);
  String? bookingId;

  final PropertyAd ad;
  late final RxString rentType;
  late final Rx<DateTime> checkIn;
  late final Rx<DateTime> checkOut;
  final quantity = 1.obs;

  // Caroussel
  final CarouselController carouselController = CarouselController();
  int _currentCarousselIndex = 0;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;

  @override
  onInit() {
    rentType = ad.preferedRentType.obs;
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month, now.day);

    checkIn = firstDate.obs;
    checkOut = firstDate.obs;

    _resetDates();

    super.onInit();

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        final newAd = await ApiService.fetchPropertyAd(ad.id);

        if (newAd != null) {
          ad.updateFrom(newAd);

          update();
        }
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _fGBGNotifierSubScription.cancel();
  }

  String get checkDifference {
    switch (rentType.value) {
      case "Monthly":
        return "$_rentPeriod Months";
      case "Weekly":
        return "$_rentPeriod Weeks";
      default:
        return "$_rentPeriod Days";
    }
  }

  int get _rentPeriod {
    // The difference in milliseconds between the checkout and the checkin date
    final checkOutCheckInMillisecondsDifference =
        checkOut.value.millisecondsSinceEpoch -
            checkIn.value.millisecondsSinceEpoch;

    final int period;

    switch (rentType.value) {
      case "Monthly":
        const oneMothDuration = 1000 * 3600 * 24 * 30;
        period =
            (checkOutCheckInMillisecondsDifference / oneMothDuration).ceil();

        break;
      case "Weekly":
        const oneWeekDuration = 1000 * 3600 * 24 * 7;
        period =
            (checkOutCheckInMillisecondsDifference / oneWeekDuration).ceil();
        break;
      default:
        const oneDayDuration = 1000 * 3600 * 24;
        period =
            (checkOutCheckInMillisecondsDifference / oneDayDuration).ceil();
        break;
    }

    return period;
  }

  Future<DateTime?> _pickDate({bool isCheckIn = false}) async {
    final DateTime? date;

    final context = Get.context!;
    final lastDate = DateTime.now().add(const Duration(days: 365 * 100));
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month, now.day);

    switch (rentType.value) {
      case "Monthly":
        final initialDate =
            isCheckIn ? firstDate : checkIn.value.add(const Duration(days: 30));
        date = await showDatePicker(
          context: context,
          lastDate: lastDate,
          firstDate: isCheckIn
              ? firstDate
              : checkIn.value.add(const Duration(days: 30)),
          initialDate: initialDate,
          selectableDayPredicate: (day) {
            if (isCheckIn) return true;
            final difference = day.difference(checkIn.value);

            return difference.inDays % 30 == 0;
          },
        );
        break;
      case "Weekly":
        final initialDate =
            isCheckIn ? firstDate : checkIn.value.add(const Duration(days: 7));
        date = await showDatePicker(
          context: context,
          lastDate: lastDate,
          firstDate: isCheckIn
              ? firstDate
              : checkIn.value.add(const Duration(days: 7)),
          initialDate: initialDate,
          selectableDayPredicate: (day) {
            if (isCheckIn) return true;
            final difference = day.difference(checkIn.value);
            return difference.inDays % 7 == 0;
          },
        );
        break;
      default:
        final initialDate =
            isCheckIn ? firstDate : checkIn.value.add(const Duration(days: 1));
        date = await showDatePicker(
          context: context,
          lastDate: lastDate,
          firstDate: isCheckIn
              ? firstDate
              : checkIn.value.add(const Duration(days: 1)),
          initialDate: initialDate,
        );
    }

    return date;
  }

  void _resetDates() {
    switch (rentType.value) {
      case "Monthly":
        checkOut(checkIn.value.add(const Duration(days: 30)));
        break;
      case "Weekly":
        checkOut(checkIn.value.add(const Duration(days: 7)));
        break;
      case "Daily":
        checkOut(checkIn.value.add(const Duration(days: 1)));
        break;
      default:
    }
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

  Future<void> bookProperty() async {
    if (AppController.me.isGuest) {
      Get.offAllNamed("/login");
      return;
    }

    final shouldContinue = await showConfirmDialog(
      "Please confirm",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);

      final res = await ApiService.getDio.post("/bookings/property-ad/", data: {
        'adId': ad.id,
        'checkIn': checkIn.value.toIso8601String(),
        'checkOut': checkOut.value.toIso8601String(),
        "rentType": rentType.value,
        "quantity": quantity.value,
      });

      if (res.statusCode == 200) {
        bookingId = res.data["bookingId"];
        isLoading(false);
        update();

        await showConfirmDialog(
          'Your request has been send to landlord. Please go to "My Bookings" '
          'and follow on with the status of the request.',
          isAlert: true,
        );
      } else if (res.statusCode == 400) {
        isLoading(false);

        if (res.data['code'] == "quantity-not-enough") {
          await showConfirmDialog(
            "Sorry! There is no more available unit in this ${ad.type}",
            isAlert: true,
          );
        } else {
          await showConfirmDialog("Something when wrong", isAlert: true);
        }
      } else if (res.statusCode == 404) {
        isLoading(false);
        await showConfirmDialog(
          "Ad not found. It may just been deleted by the poster",
          isAlert: true,
        );
      } else if (res.statusCode == 409) {
        isLoading(false);
        await showConfirmDialog(
          "You have already book this AD. Wait for the landlord reply",
          isAlert: true,
        );
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
  const ViewPropertyAd({super.key, required this.ad});

  final PropertyAd ad;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_VewPropertyController(ad));
    return Scaffold(
      appBar: AppBar(
        title: Text("${ad.type} Property"),
        backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
        actions: [
          if (!AppController.me.isGuest)
            IconButton(
              onPressed: () async {
                await addAdToFavorite(ad.toJson(), "favorites-property-ads");
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
                                  .map((e) => CachedNetworkImageProvider(e))
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
                          return PlayVideoScreen(source: e, isAsset: false);
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
                            padding: const EdgeInsets.symmetric(horizontal: 2),
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
                if (ad.isMine)
                  Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // GetBuilder<_VewPropertyController>(
                          //   id: "auto-approval",
                          //   builder: (contoller) {
                          //     if (ad.autoApprovalIsActivated) {
                          //       return IconButton(
                          //         style: IconButton.styleFrom(
                          //           backgroundColor:
                          //               Colors.grey.withOpacity(0.7),
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(50),
                          //           ),
                          //         ),
                          //         onPressed: controller.isLoading.isTrue
                          //             ? null
                          //             : controller.toggleAutoApproval,
                          //         icon: Icon(
                          //           Icons.auto_mode,
                          //           color: ad.autoApprovalIsEnabled
                          //               ? ROOMY_ORANGE
                          //               : Colors.grey,
                          //         ),
                          //       );
                          //     } else {
                          //       return ElevatedButton.icon(
                          //         style: ElevatedButton.styleFrom(
                          //           backgroundColor:
                          //               Colors.grey.withOpacity(0.7),
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(50),
                          //           ),
                          //         ),
                          //         onPressed: controller.isLoading.isTrue
                          //             ? null
                          //             : controller.enableAutoBookingApproval,
                          //         label: const Text(
                          //           "Enable",
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         icon: const Icon(
                          //           Icons.auto_mode,
                          //           color: Colors.white,
                          //         ),
                          //       );
                          //     }
                          //   },
                          // ),

                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            onPressed: controller.isLoading.isTrue
                                ? null
                                : controller.editAd,
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            onPressed: controller.isLoading.isTrue
                                ? null
                                : controller.deleteAd,
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ))
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Room type & quantity
                  Row(
                    children: [
                      Text(
                        ad.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "Available ${ad.quantity - ad.quantityTaken}",
                              style: const TextStyle(color: Colors.green),
                            ),
                            TextSpan(
                              text: " Taken ${ad.quantityTaken}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  // Location
                  Text(
                    "${ad.address["buildingName"] ?? "N/A"}, ${ad.address["location"]},"
                    " ${ad.address["city"]}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  // Prefered rent type
                  Builder(builder: (context) {
                    final String rentDuration;
                    switch (ad.preferedRentType) {
                      case "Monthly":
                        rentDuration = "Month";
                        break;
                      case "Weekly":
                        rentDuration = "Week";
                        break;
                      default:
                        rentDuration = "Day";
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
                        TextSpan(
                          text:
                              AppController.instance.country.value.currencyCode,
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextSpan(text: " / $rentDuration"),
                      ]),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    );
                  }),

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
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      children: [
                        {
                          "label": "People",
                          "asset": "assets/icons/person.png",
                          "value": "${ad.socialPreferences["numberOfPeople"]}",
                        },
                        {
                          "label": "Nationality",
                          "asset": "assets/icons/globe.png",
                          "value": "${ad.socialPreferences["nationality"]}",
                        },
                        {
                          "label": "Smoking",
                          "asset": "assets/icons/smoking.png",
                          "value": ad.socialPreferences["smoking"] == true
                              ? "Yes"
                              : "No",
                        },
                        {
                          "label": "Gender",
                          "asset": "assets/icons/gender.png",
                          "value": ad.socialPreferences["gender"],
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
                          rowCrossAxisAlignment: CrossAxisAlignment.center,
                          title: Text("${e["label"]}"),
                          subTitle: Text("${e["value"]}"),
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
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: ALL_AMENITIES
                          .where((e) => ad.amenities.contains(e["value"]))
                          .map((e) {
                        return AdOverViewItem(
                          rowCrossAxisAlignment: CrossAxisAlignment.center,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              formatMoney(
                                (ad.monthlyPrice + ad.monthlyCommission) *
                                    AppController.convertionRate,
                              ),
                              formatMoney(
                                (ad.weeklyPrice + ad.weeklyCommission) *
                                    AppController.convertionRate,
                              ),
                              formatMoney(
                                (ad.dailyPrice + ad.dailyCommission) *
                                    AppController.convertionRate,
                              ),
                            ].map((e) => Text(e)).toList(),
                          ),
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
                        Expanded(child: Text(ad.deposit ? "Yes" : "No")),
                        Expanded(
                          child: Text(
                            ad.deposit
                                ? formatMoney((ad.depositPrice!) *
                                    AppController.convertionRate)
                                : "N/A",
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 20),

                  //  Booking date
                  if (!ad.isMine) ...[
                    const Text(
                      "Date",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text("Choose rent type", style: TextStyle()),
                    SizedBox(
                      width: Get.width * 0.7,
                      child: InlineDropdown<String>(
                        labelWidth: 0,
                        value: controller.rentType.value,
                        items: const ["Monthly", "Weekly", "Daily"],
                        onChanged: controller.isLoading.isTrue
                            ? null
                            : (val) {
                                if (val != null) {
                                  controller.rentType(val);
                                  controller._resetDates();
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      return Row(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Check in", style: TextStyle()),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () async {
                                  final date = await controller._pickDate(
                                      isCheckIn: true);

                                  if (date != null) {
                                    controller.checkIn(date);
                                    controller._resetDates();
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.calendar,
                                  color: Colors.grey,
                                ),
                                label: Text(
                                  Jiffy.parseFromDateTime(
                                          controller.checkIn.value)
                                      .yMd,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Check out", style: TextStyle()),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () async {
                                  final date = await controller._pickDate();

                                  if (date != null) {
                                    controller.checkOut(date);
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.calendar,
                                  color: Colors.grey,
                                ),
                                label: Text(
                                  Jiffy.parseFromDateTime(
                                          controller.checkOut.value)
                                      .yMd,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                    const Divider(height: 20),
                  ], // Google map representing the location of the properrty
                  // if (ad.cameraPosition != null) ...[
                  ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Location",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${ad.address['buildingName']}, "
                          "${ad.address['location']}, "
                          "${ad.address['city']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Image.asset("assets/images/map.jpg")
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  //  Booking Button
                  if (!ad.isMine) ...[
                    GetBuilder<_VewPropertyController>(builder: (controller) {
                      return SizedBox(
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
                                    controller.bookProperty();
                                  }
                                },
                          child: Text(
                            controller.bookingId != null
                                ? "Cancel booking"
                                : "Book property",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
