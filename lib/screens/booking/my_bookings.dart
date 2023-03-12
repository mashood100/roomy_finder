import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/models/property_booking.dart';
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
          backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
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

          return GetBuilder<_MyBookingsController>(builder: (controller) {
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

                return GestureDetector(
                  onTap: () async {
                    await Get.to(
                      () => ViewPropertyBookingScreen(booking: booking),
                    );
                    controller.update();
                  },
                  child: Card(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: CachedNetworkImage(
                            imageUrl: booking.ad.images[0],
                            height: 120,
                            width: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Label(
                                label: "Property : ",
                                value: "${booking.quantity} ${booking.ad.type}"
                                    "${booking.quantity > 1 ? "s" : ""}",
                                boldValue: true,
                              ),
                              Label(
                                label: "Location : ",
                                value: "${booking.ad.address["location"]}",
                                boldValue: true,
                              ),
                              Label(
                                label: "Status     : ",
                                value: booking.isPayed
                                    ? "Paid"
                                    : booking.capitaliezedStatus,
                                boldValue: true,
                                valueColor: booking.isPayed || booking.isOffered
                                    ? Colors.green
                                    : booking.isPending
                                        ? Colors.blue
                                        : Colors.red,
                              ),
                              Label(
                                label: "Date  : ",
                                value: Jiffy(booking.createdAt).yMMMEdjm,
                                fontSize: 12,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
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
