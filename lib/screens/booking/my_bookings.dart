import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/models/roommate_booking.dart';
import 'package:roomy_finder/screens/booking/view_property_booking.dart';

class _MyBookingsController extends LoadingController {
  final RxList<PropertyBooking> propertyBookings = <PropertyBooking>[].obs;

  @override
  void onInit() {
    _fetchData();
    super.onInit();
  }

  Future<void> _fetchData({bool isReFresh = true}) async {
    try {
      isLoading(true);
      hasFetchError(false);
      final query = <String, dynamic>{};

      final res = await ApiService.getDio
          .get("/bookings/my-bookings", queryParameters: query);

      final data = (res.data as List).map((e) => PropertyBooking.fromMap(e));

      if (isReFresh) {
        propertyBookings.clear();
      }
      propertyBookings.addAll(data);
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      hasFetchError(true);
    } finally {
      isLoading(false);
    }
  }
}

class MyBookingsCreen extends StatelessWidget {
  const MyBookingsCreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_MyBookingsController());
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          actions: [
            Obx(() {
              return IconButton(
                onPressed:
                    controller.isLoading.isTrue ? null : controller._fetchData,
                icon: const Icon(Icons.refresh),
              );
            })
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (controller.hasFetchError.isTrue) {
            return Center(
              child: Column(
                children: [
                  const Text("Failed to fetch data"),
                  OutlinedButton(
                    onPressed: controller._fetchData,
                    child: const Text("Refresh"),
                  ),
                ],
              ),
            );
          }

          return Builder(builder: (context) {
            if (controller.propertyBookings.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const Text("No data."),
                    OutlinedButton(
                      onPressed: controller._fetchData,
                      child: const Text("Refresh"),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemBuilder: (context, index) {
                final booking = controller.propertyBookings[index];
                final title =
                    "${booking.ad.type} in ${booking.ad.address["city"]},"
                    " ${booking.ad.address["location"]}";
                final subTitle =
                    "${booking.status}, Since ${relativeTimeText(booking.createdAt)}"
                    "\nBy ${booking.poster.fullName}";

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(booking.ad.images[0]),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subTitle),
                  onTap: () {
                    Get.to(() => ViewPropertyBookingScreen(booking: booking));
                  },
                );
              },
              itemCount: controller.propertyBookings.length,
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            );
          });
        }),
      ),
    );
  }
}

class RoommateBookingWidget extends StatelessWidget {
  final RoommateBooking booking;
  final void Function()? onTap;
  const RoommateBookingWidget({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Card(
          child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "About ad",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Label(label: "Type", value: "Property"),
            Label(label: "Object", value: booking.ad.type),

            Text(
              "About client${!booking.isMine ? " (me)" : ""}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Label(label: "Name", value: booking.poster.fullName),
            // Label(label: "Email", value: booking.poster.email),
            // Label(label: "Phone", value: booking.poster.phone),
            const Divider(),
            Label(label: "Status", value: booking.status),
            Row(
              children: [
                Text("Booked on", style: textTheme.bodySmall),
                const Spacer(),
                Text(relativeTimeText(booking.createdAt)),
              ],
            ),
          ],
        ),
      )),
    );
  }
}
