import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
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
      "Do you really want to delete this ad",
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
    try {
      isLoading(true);

      final res = await ApiService.getDio.post("/bookings/property-ad/", data: {
        'landlordId': ad.poster.id,
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
          "Your request have been sent to the landlord",
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

  void _viewImage(String source) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        return CachedNetworkImage(imageUrl: source);
      },
    );
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
        title: const Text("Looking for properties"),
        backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...ad.images.map(
                    (e) => GestureDetector(
                      onTap: () => controller._viewImage(e),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: CachedNetworkImage(
                            imageUrl: e,
                            height: 250,
                            fit: BoxFit.fitHeight,
                            errorWidget: (ctx, e, trace) {
                              return const SizedBox(
                                child: CupertinoActivityIndicator(
                                  radius: 30,
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
                        return PlayVideoScreen(source: e, isAsset: false);
                      }),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 1),
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
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${ad.quantity} ${ad.type} in ${ad.address["city"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Location : ${ad.address["location"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Building : ${ad.address["buildingName"]}"
                    ", Floor number : ${ad.address["floorNumber"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "ID ${ad.id}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30),
                  const Text("Pricing", style: TextStyle(fontSize: 14)),
                  Text(
                    "Monthly  : ${formatMoney((ad.monthlyPrice + ad.monthlyCommission) * AppController.cnvertionRate)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Weekly   : ${formatMoney((ad.weeklyPrice + ad.weeklyCommission) * AppController.cnvertionRate)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Daily  : ${formatMoney((ad.dailyPrice + ad.dailyCommission) * AppController.cnvertionRate)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (ad.deposit)
                    Text(
                      "Deposit fee : ${formatMoney(ad.depositPrice! * AppController.cnvertionRate)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  const Divider(height: 20),
                  const Text("Availability", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(30)),
                              border: Border.all(color: Colors.grey)),
                          child: Text(
                            "${ad.quantityTaken} taken",
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(30)),
                              border: Border.all(color: Colors.green)),
                          child: Text(
                            "${ad.quantity} available",
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Overview", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    childAspectRatio: 2.5,
                    children: [
                      PropertyAdOverviewItemWidget(
                        icon: const Icon(Icons.group),
                        label: "Number of people",
                        value:
                            "${ad.socialPreferences["numberOfPeople"]} peoples",
                      ),
                      PropertyAdOverviewItemWidget(
                        icon: const Icon(Icons.smoking_rooms_rounded),
                        label: "Smoking",
                        value: ad.socialPreferences["smoking"] == true
                            ? "Allowed"
                            : "Not allowed",
                      ),
                      PropertyAdOverviewItemWidget(
                        icon: const Icon(Icons.public),
                        label: "Nationality preferred",
                        value: "${ad.socialPreferences["nationality"]}",
                      ),
                      PropertyAdOverviewItemWidget(
                        icon: Icon(ad.socialPreferences["drinking"] == true
                            ? Icons.local_drink_sharp
                            : Icons.no_drinks),
                        label: "Drinking",
                        value: ad.socialPreferences["drinking"] == true
                            ? "Allowed"
                            : "Not allowed",
                      ),
                      PropertyAdOverviewItemWidget(
                        icon: Icon(ad.socialPreferences["gender"] == "Male"
                            ? Icons.male
                            : Icons.female),
                        label: "Gender preferred",
                        value: "${ad.socialPreferences["gender"]}",
                      ),
                      PropertyAdOverviewItemWidget(
                        icon: const Icon(Icons.family_restroom),
                        label: "Visitors",
                        value: ad.socialPreferences["visitors"] == true
                            ? "Allowed"
                            : "Not allowed",
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  const Text("Description", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(
                    ad.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  const Text("Amenities", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    childAspectRatio: 5,
                    children: ad.amenties.map((e) {
                      final icondata = _getIconDataFromAmenties(e);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icondata),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Google map representing the location of the properrty
                  if (ad.cameraPosition != null)
                    const Text("Map location", style: TextStyle(fontSize: 14)),
                  if (ad.cameraPosition != null)
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

                  if (!ad.isMine && controller.bookingId == null) ...[
                    const Text(
                      "Booking",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('Which rent type do you want?'.tr),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Rent type',
                      ),
                      value: controller.rentType.value,
                      items: ["Monthly", "Weekly", "Daily"]
                          .map((e) => DropdownMenuItem<String>(
                              value: e, child: Text(e)))
                          .toList(),
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
                          border: Border.all(color: Colors.blue),
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
                                Text(Jiffy(controller.checkIn.value).yMMMEd),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Check Out :"),
                                const SizedBox(width: 10),
                                Text(Jiffy(controller.checkOut.value).yMMMEd),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    final date = await controller._pickDate();

                                    if (date != null) {
                                      controller.checkOut(date);
                                    }
                                  },
                                  child: const Text("Change check Out"),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              children: [
                                Text(
                                  "Quantity : ${controller.quantity} "
                                  "${controller.ad.type}",
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
                  if (!ad.isMine)
                    GetBuilder<_VewPropertyController>(builder: (controller) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.bookingId != null
                                ? Colors.red
                                : const Color.fromRGBO(96, 15, 116, 1),
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
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Builder(builder: (context) {
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
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        return const SizedBox();
      }),
    );
  }
}

IconData _getIconDataFromAmenties(String search) {
  switch (search) {
    case "Close to metro":
      return Icons.car_repair;
    case "Balcony":
      return Icons.window;
    case "Kitchen appliances":
      return Icons.kitchen;
    case "Barking":
      return Icons.bakery_dining;
    case "WIFI":
      return Icons.wifi;
    case "TV":
      return Icons.tv;
    case "Shared gym":
      return Icons.sports_gymnastics;
    case "Washer":
      return Icons.wash;
    case "Cleaning included":
      return Icons.cleaning_services;
    case "Near to supermarket":
      return Icons.shopify;
    case "Shared swimming pool":
      return Icons.water;
    case "Near to pharmacy":
      return Icons.health_and_safety;
    default:
      return Icons.widgets;
  }
}
