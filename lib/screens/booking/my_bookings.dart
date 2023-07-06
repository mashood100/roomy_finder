import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/booking/view_property_booking.dart';
import 'package:roomy_finder/utilities/data.dart';

const _statuses = ["All", "Pending", "Offered", "Active", "History"];

class _MyBookingsController extends LoadingController
    with GetSingleTickerProviderStateMixin {
  final RxList<PropertyBooking> _propertyBookings = <PropertyBooking>[].obs;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> fcmStream;

  late TabController _tabController;

  @override
  void onInit() {
    _fetchData();
    super.onInit();

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _fetchData();
      }
    });

    _tabController = TabController(length: _statuses.length, vsync: this);

    fcmStream = FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;

      if (data["event"] == "new-booking") {
        ApiService.fetchBooking(data["bookingId"].toString()).then((b) {
          if (b != null) {
            showToast("New booking");
            _propertyBookings.insert(0, b);
            update();
          }
        });
      } else if (data["event"] == "booking-cancelled") {
        final id = data["bookingId"].toString();
        _propertyBookings.removeWhere((e) => e.id == id);
        showToast("One booking cancelled");
        update();
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _fGBGNotifierSubScription.cancel();
    fcmStream.cancel();
    _tabController.dispose();
    PropertyBooking.unViewBookingsCount(0);
  }

  Future<void> _fetchData({bool isReFresh = true}) async {
    try {
      isLoading(true);
      hasFetchError(false);
      final query = <String, dynamic>{};

      final res = await ApiService.getDio
          .get("/bookings/my-bookings", queryParameters: query);
      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            var propertyBooking = PropertyBooking.fromMap(e);
            return propertyBooking;
          } catch (e) {
            Get.log("$e");
            return null;
          }
        });

        if (isReFresh) {
          _propertyBookings.clear();
        }
        _propertyBookings.addAll(data.whereType<PropertyBooking>());
      } else {
        showToast("Failed to load data");
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      hasFetchError(true);
    } finally {
      isLoading(false);
      update();
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
      child: GetBuilder<_MyBookingsController>(builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("My Bookings"),
            backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
            bottom: TabBar(
              tabs: _statuses.map((e) {
                return Tab(
                  text: e,
                );
              }).toList(),
              labelColor: ROOMY_ORANGE,
              unselectedLabelColor: Colors.white,
              controller: controller._tabController,
              indicatorColor: ROOMY_ORANGE,
              labelPadding: const EdgeInsets.symmetric(horizontal: 5),
            ),
            actions: [
              IconButton(
                onPressed:
                    controller.isLoading.isTrue ? null : controller._fetchData,
                icon: const Icon(Icons.refresh),
              )
            ],
          ),
          body: Stack(
            children: [
              Builder(builder: (context) {
                if (controller.hasFetchError.isTrue) {
                  return Center(
                    child: Column(
                      children: [
                        const Spacer(),
                        const Text("Failed to fetch data"),
                        TextButton(
                          onPressed: controller._fetchData,
                          child: const Text("Refresh"),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: controller._tabController,
                  children: _statuses.map((status) {
                    var data = controller._propertyBookings.where((e) {
                      List<String> belongs;
                      switch (status) {
                        case "Pending":
                          belongs = ["pending"];
                          break;
                        case "Offered":
                          belongs = ["offered"];
                          break;
                        case "Active":
                          belongs = ["active"];
                          break;
                        default:
                          belongs = ["declined", "cancelled", "terminated"];
                      }
                      if (status == "All") return true;
                      return belongs.contains(e.status);
                    });

                    if (data.isEmpty) {
                      return const Center(
                          child: Text(
                        "No data",
                        style: TextStyle(color: Colors.grey),
                      ));
                    }

                    return SingleChildScrollView(
                      padding:
                          const EdgeInsetsDirectional.symmetric(horizontal: 5),
                      child: Column(
                        children: data.map((booking) {
                          return _BookingCard(
                            booking: booking,
                            onTap: () async {
                              await Get.to(
                                () => ViewPropertyBookingScreen(
                                  booking: booking,
                                ),
                              );

                              controller.update();
                              ApiService.setUnreadBookingCount();
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              }),
              if (controller.isLoading.isTrue) const LoadingPlaceholder(),
            ],
          ),
        );
      }),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    this.onTap,
  });

  final PropertyBooking booking;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Badge(
        isLabelVisible: booking.isMine && !booking.isViewedByLandlord,
        child: Card(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: booking.ad.images.isEmpty
                    ? Image.asset(
                        "assets/images/default_room.png",
                        height: 120,
                        width: 140,
                        fit: BoxFit.cover,
                      )
                    : LoadingProgressImage(
                        image: CachedNetworkImageProvider(booking.ad.images[0]),
                        height: 120,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
              ),
              Expanded(
                child: Padding(
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
                        value: booking.capitaliezedStatus,
                        boldValue: true,
                        valueColor: booking.isPayed || booking.isOffered
                            ? Colors.green
                            : booking.isPending
                                ? Colors.blue
                                : Colors.red,
                      ),
                      Text(
                        Jiffy.parseFromDateTime(booking.createdAt).yMMMEdjm,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
