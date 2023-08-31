import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/booking/view_property_booking.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/utilities/data.dart';

const _statuses = ["All", "Pending", "Offered", "Active", "History"];

class _MyBookingsController extends LoadingController
    with GetSingleTickerProviderStateMixin {
  final RxList<PropertyBooking> bookings = <PropertyBooking>[].obs;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> fcmStream;

  late TabController _tabController;
  late final Timer _timer;

  @override
  void onInit() {
    _fetchData();

    super.onInit();

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _fetchData(isSilent: true);
      }
    });

    _tabController = TabController(length: _statuses.length, vsync: this);

    fcmStream =
        FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;

      if (!data.containsKey("bookingId")) return;

      ApiService.setUnreadBookingCount();

      final b = await ApiService.fetchBooking(data["bookingId"].toString());
      if (b == null) return;

      switch (data["event"]) {
        case "new-booking":
          if (ModalRoute.of(Get.context!)?.isCurrent == true) {
            showToast("New booking");
          }
          bookings.insert(0, b);
          break;

        default:
          final target = bookings.firstWhereOrNull((e) => e.id == b.id);
          if (target != null) {
            target.updateFrom(b);
          } else {
            _fetchData(isSilent: true, isReFresh: true);
          }
      }
      update();
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (hasFetchError.isTrue) _fetchData(isSilent: true);
    });
  }

  @override
  void onClose() {
    super.onClose();
    _fGBGNotifierSubScription.cancel();
    fcmStream.cancel();
    _tabController.dispose();

    _timer.cancel();
  }

  Future<void> _fetchData(
      {bool isReFresh = true, bool isSilent = false}) async {
    try {
      if (!isSilent) isLoading(true);
      hasFetchError(false);
      update();
      final map = <String, dynamic>{};

      final res =
          await ApiService.getDio.get("/bookings/my-bookings", data: map);
      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            var propertyBooking = PropertyBooking.fromMap(e);
            return propertyBooking;
          } catch (e) {
            // Get.log("$trace");
            return null;
          }
        });

        if (isReFresh) {
          bookings.clear();
        }
        bookings.addAll(data.whereType<PropertyBooking>());
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

class MyBookingsCreen extends StatelessWidget implements HomeScreenSupportable {
  const MyBookingsCreen({super.key, this.showNavBar});
  final bool? showNavBar;

  @override
  void onTabIndexSelected(int index) {}

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_MyBookingsController());
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: GetBuilder<_MyBookingsController>(builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("My Bookings"),
            backgroundColor: ROOMY_PURPLE,
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
                    var data = controller.bookings.where((e) {
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
                              await Get.to(() {
                                return ViewPropertyBookingScreen(b: booking);
                              });

                              controller.update();
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
          bottomNavigationBar:
              showNavBar == true ? const HomeBottomNavigationBar() : null,
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
                    Builder(builder: (context) {
                      var valueColor = Colors.blue;

                      switch (booking.status) {
                        case "pending":
                          valueColor = Colors.blue;

                          break;
                        case "offered":
                        case "active":
                          valueColor = Colors.green;

                          break;
                        case "declined":
                        case "cancelled":
                        case "terminated":
                          valueColor = Colors.red;

                          break;
                      }

                      return Label(
                        label: "Status     : ",
                        value: booking.capitaliezedStatus,
                        boldValue: true,
                        valueColor: valueColor,
                      );
                    }),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Jiffy.parseFromDateTime(booking.createdAt).yMMMEdjm,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if ((booking.isMine && !booking.isViewedByLandlord ||
                            !booking.isMine && !booking.isViewedByClient))
                          const Icon(
                            Icons.circle,
                            color: Colors.red,
                            size: 15,
                          )
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
