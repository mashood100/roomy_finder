import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:readmore/readmore.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/amenities_widget.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/square_box_wrapper.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/share_ad.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  onInit() {
    rentType = ad.preferedRentType.obs;
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month, now.day);

    checkIn = firstDate.obs;
    checkOut = firstDate.obs;

    _resetDates();

    super.onInit();
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

  Future<void> editAd(PropertyAd ad) async {
    Get.to(() => PostPropertyAdScreen(oldData: ad));
  }

  Future<void> deleteAd(PropertyAd ad) async {
    final shouldContinue = await showConfirmDialog(
      "Please confirm",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);
      final res = await ApiService.getDio.delete("/ads/property-ad/${ad.id}");

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
        final message = res.data["code"] == "is-booked"
            ? "This ad is booked. You must decline all "
                "the bookings releted to this ad before deleting it"
            : "There is a deal on this ad. You must end all the deals "
                "releted to this ad before deleting it";

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

  Future<void> bookProperty(PropertyAd ad) async {
    if (AppController.me.isGuest) {
      Get.offAllNamed("/registration");
      return;
    }
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
          "Your booking request has been approved. "
          "Please pay the rent fee to proceed with the booking",
          isAlert: true,
        );
      } else if (res.statusCode == 400) {
        isLoading(false);

        if (res.data['code'] == "quantity-not-enough") {
          await showConfirmDialog(
            "Quantity too large. Possible is ${res.data['possible']}",
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

  Future<void> cancelBooking(PropertyAd ad) async {
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
        showGetSnackbar(
          "Failed to cancel booking. Please try again",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log("$e");
      showGetSnackbar(
        "Failed to cancel booking. Please try again",
        severity: Severity.error,
      );
    } finally {
      isLoading(false);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const SizedBox(height: 1),
              SquareBoxWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CarouselSlider(
                          carouselController: controller.carouselController,
                          items: [
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
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
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
                                  ),
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
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
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
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    onPressed: controller.isLoading.isTrue
                                        ? null
                                        : () => controller.editAd(ad),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    onPressed: controller.isLoading.isTrue
                                        ? null
                                        : () {
                                            controller.deleteAd(ad);
                                          },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${ad.type} to rent",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(() {
                          return Text(
                            formatMoney(
                              ad.prefferedRentDisplayPrice *
                                  AppController.instance.country.value
                                      .aedCurrencyConvertRate,
                            ),
                            style: const TextStyle(fontSize: 16),
                          );
                        }),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.room, color: ROOMY_ORANGE),
                            const SizedBox(width: 5),
                            Text(
                              "${ad.address["city"]}, ${ad.address["location"]}",
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Available ${ad.quantity - ad.quantityTaken}",
                              style: const TextStyle(
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Taken ${ad.quantityTaken}",
                              style: const TextStyle(
                                color: ROOMY_ORANGE,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (ad.description != null && ad.description!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
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
                          colorClickableText: ROOMY_PURPLE,
                        ),
                      ),
                  ],
                ),
              ),
              if (ad.description != null && ad.description!.isNotEmpty)
                const SizedBox(height: 20),

              // Pricing
              SquareBoxWrapper(
                child: Builder(builder: (context) {
                  var data = [
                    {
                      "label": "Monthly",
                      "value": formatMoney(
                        (ad.monthlyPrice + ad.monthlyCommission) *
                            AppController.convertionRate,
                        name: "",
                      ),
                    },
                    {
                      "label": "Weekly",
                      "value": formatMoney(
                        (ad.weeklyPrice + ad.weeklyCommission) *
                            AppController.convertionRate,
                        name: "",
                      ),
                    },
                    {
                      "label": "Daily",
                      "value": formatMoney(
                        (ad.dailyPrice + ad.dailyCommission) *
                            AppController.convertionRate,
                        name: "",
                      ),
                    },
                  ];
                  if (ad.deposit && ad.depositPrice != null) {
                    data.add({
                      "label": "Deposit",
                      "value": formatMoney(
                        (ad.depositPrice!) * AppController.convertionRate,
                        name: "",
                      ),
                    });
                  }
                  return DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontFamily: "Avro",
                      fontWeight: FontWeight.bold,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: data.map((e) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "${e["label"]}",
                              style: const TextStyle(
                                color: ROOMY_ORANGE,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "${e["value"]}",
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              AppController.instance.country.value.currencyCode,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Amenities
              SquareBoxWrapper(child: AmenitiesWidget(ad: ad)),
              const SizedBox(height: 20),
              // Preferrences
              SquareBoxWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "SHARING/HOUSING PREFERENCES",
                        style: TextStyle(
                          fontSize: 14,
                          color: ROOMY_ORANGE,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        {
                          "label": "People    ",
                          "asset": "assets/icons/people_2.png",
                          "value": "${ad.socialPreferences["numberOfPeople"]}",
                        },
                        {
                          "label": "Nationality",
                          "asset": "assets/icons/globe.png",
                          "value": "${ad.socialPreferences["nationality"]}",
                        },
                        {
                          "label": "Visitors",
                          "asset": "assets/icons/people_3.png",
                          "value": ad.socialPreferences["visitors"] == true
                              ? "Allowed"
                              : "Not Allowed",
                          "color": ad.socialPreferences["visitors"] == true
                              ? Colors.green
                              : Colors.red,
                        },
                        {
                          "label": "Drinking",
                          "asset": "assets/icons/drink.png",
                          "value": ad.socialPreferences["drinking"] == true
                              ? "Allowed"
                              : "Not Allowed",
                          "color": ad.socialPreferences["drinking"] == true
                              ? Colors.green
                              : Colors.red,
                        },
                        {
                          "label": "Gender  ",
                          "asset": "assets/icons/gender.png",
                          "value": ad.socialPreferences["gender"],
                        },
                        {
                          "label": "Smoking",
                          "asset": "assets/icons/smoking.png",
                          "value": ad.socialPreferences["smoking"] == true
                              ? "Allowed"
                              : "Not Allowed",
                          "color": ad.socialPreferences["smoking"] == true
                              ? Colors.green
                              : Colors.red,
                        },
                      ].map((e) {
                        return Container(
                          decoration: shadowedBoxDecoration,
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Image.asset(
                                  "${e["asset"]}",
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: ROOMY_ORANGE,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${e["label"]}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${e["value"]}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          e["color"] as Color? ?? Colors.black,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

              // Google map representing the location of the properrty
              if (ad.cameraPosition != null)
                SquareBoxWrapper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Map location",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: ad.cameraPosition?.target ??
                                const LatLng(1254, 412),
                            zoom: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              // Booking
              if (!ad.isMine)
                SquareBoxWrapper(
                  // padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...[
                        const Center(
                          child: Text(
                            "BOOKING",
                            style: TextStyle(
                              fontSize: 14,
                              color: ROOMY_ORANGE,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('Which rent type do you want?'.tr),
                        InlineDropdown<String>(
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
                        const SizedBox(height: 20),
                        Obx(() {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("Check In :"),
                                    const SizedBox(width: 10),
                                    Text(
                                        Jiffy(controller.checkIn.value).yMMMEd),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("Check Out :"),
                                    const SizedBox(width: 10),
                                    Text(Jiffy(controller.checkOut.value)
                                        .yMMMEd),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("Total : "),
                                    const SizedBox(width: 10),
                                    Text(controller.checkDifference),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () async {
                                        final date = await controller._pickDate(
                                            isCheckIn: true);

                                        if (date != null) {
                                          controller.checkIn(date);
                                          controller._resetDates();
                                        }
                                      },
                                      child: const Text("Change check In"),
                                    ),
                                    OutlinedButton(
                                      onPressed: () async {
                                        final date =
                                            await controller._pickDate();

                                        if (date != null) {
                                          controller.checkOut(date);
                                        }
                                      },
                                      child: const Text("Change check Out"),
                                    ),
                                  ],
                                ),
                                const Divider(thickness: 5),
                                Row(
                                  children: [
                                    Text(
                                      "Quantity  :  ${controller.quantity}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: controller.quantity <= 1
                                          ? null
                                          : () => controller.quantity(
                                              controller.quantity.value - 1),
                                      icon: const Icon(Icons.remove_outlined),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: controller.quantity >=
                                              (controller.ad.quantity -
                                                  controller.ad.quantityTaken)
                                          ? null
                                          : () => controller.quantity(
                                              controller.quantity.value + 1),
                                      icon: const Icon(Icons.add_outlined),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 20),
                      GetBuilder<_VewPropertyController>(builder: (controller) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ROOMY_PURPLE,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              side: const BorderSide(color: ROOMY_PURPLE),
                            ),
                            onPressed: controller.isLoading.isTrue
                                ? null
                                : () {
                                    if (controller.bookingId != null) {
                                      controller.cancelBooking(ad);
                                    } else {
                                      controller.bookProperty(ad);
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
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
