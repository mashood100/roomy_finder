import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/alert.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/booking/pay_property_booking.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';

class _ViewPropertyBookingScreenController extends LoadingController {
  final PropertyBooking booking;

  _ViewPropertyBookingScreenController(this.booking);

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> fcmStream;

  @override
  void onInit() {
    super.onInit();

    if (booking.isMine) _markBookingAsViewed();

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        final b = await ApiService.fetchBooking(booking.id);

        if (b != null) {
          booking.updateFrom(b);
          update();
        }
      }
    });

    fcmStream =
        FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;
      final id = data["bookingId"];

      if (id != booking.id) return;

      switch (data["event"]) {
        case "booking-offered":
          booking.status = "offered";
          showToast("Booking offered");
          update();

          break;
        case "booking-declined":
          booking.status = "declined";
          await showConfirmDialog(
            "This booking have just been declined by landlord",
            isAlert: true,
          );
          update();

          break;
        case "booking-cancelled":
          booking.status = "cancelled";
          await showConfirmDialog(
            "This booking have just been cancelled by tenant",
            isAlert: true,
          );
          // Get.back();

          break;
        case "pay-property-rent-fee-paid-cash":
          booking.isPayed = true;
          booking.paymentService = "PAY CASH";
          showToast("Booking paid cash");
          update();

          break;
        case "pay-property-rent-fee-completed-client":
        case "pay-property-rent-fee-completed-landlord":
          final paymentService = data["paymentService"];
          booking.isPayed = true;
          booking.paymentService = paymentService;
          showToast("Booking paid by $paymentService");
          update();

          break;

        default:
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    fcmStream.cancel();
    _fGBGNotifierSubScription.cancel();
  }

  Future<void> acceptBooking() async {
    final shouldContinue = await showConfirmDialog("Accept request?");
    if (shouldContinue != true) return;
    try {
      isLoading(true);
      final res = await ApiService.getDio
          .post("/bookings/property-ad/${booking.id}/offer");

      if (res.statusCode == 200) {
        showConfirmDialog(
          "Booking accepted successfully.",
          isAlert: true,
        );
        booking.status = 'offered';
        update();
      } else if (res.statusCode == 404) {
        showConfirmDialog(
          "Booking not found",
          isAlert: true,
        );
      } else {
        Get.log(res.statusCode.toString());
        showConfirmDialog(
          "Something when wrong. Please try again later",
          isAlert: true,
        );
      }
    } catch (e) {
      Get.log('$e');
      showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
    } finally {
      isLoading(false);
    }
  }

  Future<void> declineBooking() async {
    final shouldContinue = await showConfirmDialog(
      "Decline request?",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);
      final res = await ApiService.getDio.post(
        "/bookings/property-ad/landlord/cancel",
        data: {"bookingId": booking.id},
      );

      if (res.statusCode == 200) {
        await showConfirmDialog(
          "Booking cancelled successfully.",
          isAlert: true,
        );
        isLoading(false);
        update();
        booking.status = 'declined';
        Get.back();
      } else if (res.statusCode == 404) {
        showConfirmDialog(
          "Booking not found",
          isAlert: true,
        );
      } else {
        Get.log(res.statusCode.toString());
        showGetSnackbar(
          "Something when wrong. Please try again later",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log('$e');
      showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
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
        data: {'bookingId': booking.id},
      );

      if (res.statusCode == 200) {
        booking.status = "cancelled";
        isLoading(false);
        update();

        await showConfirmDialog(
          "Booking cancelled",
          isAlert: true,
        );
        Get.back();
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

  Future<void> payRent() async {
    await Get.to(() => PayProperyBookingScreen(booking: booking));

    update();
  }

  Future<void> _markBookingAsViewed() async {
    try {
      if (booking.isViewedByLandlord) return;

      final res = await ApiService.getDio.get(
        "/bookings/property-ad/${booking.id}/mark-booking-as-view",
      );

      if (res.statusCode == 200) {
        booking.isViewedByLandlord = true;
      }
    } catch (e) {
      Get.log("$e");
    }
  }

  Future<void> chatWithClient() async {
    moveToChatRoom(AppController.me, booking.client, booking: booking);
  }

  Future<void> chatWithLandlord() async {
    moveToChatRoom(AppController.me, booking.poster, booking: booking);
  }
}

class ViewPropertyBookingScreen extends StatelessWidget {
  const ViewPropertyBookingScreen({super.key, required this.booking});
  final PropertyBooking booking;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ViewPropertyBookingScreenController(booking));
    return Scaffold(
      appBar: AppBar(
        title: const Text('View booking'),
        backgroundColor: ROOMY_PURPLE,
      ),
      body: Obx(() {
        return Stack(
          children: [
            GetBuilder<_ViewPropertyBookingScreenController>(
                builder: (controller) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (!booking.isPayed &&
                          !booking.isCancelled &&
                          !booking.isDeclined) ...[
                        const SizedBox(height: 10),
                        Alert(
                          text: booking.isMine
                              ? "You will see the tenant information after "
                                  "you have accepted the booking and he paid the rent."
                              : "You will see the landlord information after "
                                  "he have accepted the booking and you have paid rent.",
                          severity: Severity.info,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // About booking
                      const Text(
                        "About booking",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Card(
                        color: Colors.white,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Label(label: "Property", value: booking.ad.type),
                              if (booking.isPayed)
                                Label(
                                  label: "Property location",
                                  value:
                                      "${booking.ad.address['city']}, ${booking.ad.address['location']}",
                                ),
                              // Label(label: "Rent type", value: booking.rentType),
                              Label(
                                label: "Quantity booked",
                                value: "${booking.quantity} ${booking.ad.type}"
                                    "${booking.quantity > 1 ? "s" : ""}",
                              ),
                              Label(
                                label: "Booking date",
                                value:
                                    Jiffy.parseFromDateTime(booking.createdAt)
                                        .yMMMEd,
                              ),
                              Label(
                                label: "Check In",
                                value: Jiffy.parseFromDateTime(booking.checkIn)
                                    .yMMMEd,
                              ),
                              Label(
                                label: "Check Out",
                                value: Jiffy.parseFromDateTime(booking.checkOut)
                                    .yMMMEd,
                              ),
                              Label(
                                label: "Status",
                                value: booking.capitaliezedStatus,
                                valueColor: booking.isOffered
                                    ? Colors.green
                                    : booking.isPending
                                        ? Colors.blue
                                        : Colors.red,
                              ),
                              if (booking.isOffered)
                                Label(
                                  label: "Payment status",
                                  value: booking.isPayed
                                      ? 'Paid'
                                      : "Payment required",
                                ),
                            ],
                          ),
                        ),
                      ),
                      // About property
                      if (booking.isPayed) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "About Property",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      if (booking.isPayed)
                        Card(
                          color: Colors.white,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Label(
                                    label: "Property", value: booking.ad.type),
                                Label(
                                  label: "Property location",
                                  value: "${booking.ad.address['city']}, "
                                      "${booking.ad.address['location']}",
                                ),
                                Label(
                                  label: "Building",
                                  value:
                                      "${booking.ad.address['buildingName']}",
                                ),
                                Label(
                                  label: "Apartment number",
                                  value:
                                      "${booking.ad.address['appartmentNumber']}",
                                ),
                                Label(
                                  label: "Floor number",
                                  value: "${booking.ad.address['floorNumber']}",
                                ),
                              ],
                            ),
                          ),
                        ),

                      // About landlord
                      if (!booking.isMine && booking.isPayed) ...[
                        const SizedBox(height: 10),
                        Text(
                          booking.ad.posterType == "Landlord"
                              ? "About Landlond"
                              : "About Agent/Broker",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      if (!booking.isMine && booking.isPayed)
                        Card(
                          color: Colors.white,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: booking.ad.posterType == "Landlord"
                                  ? [
                                      Label(
                                        label: "Name",
                                        value: booking.poster.fullName,
                                      ),
                                      Label(
                                        label: "Country",
                                        value: booking.poster.country ?? 'N/A',
                                      ),
                                      Label(
                                        label: "Email",
                                        value: booking.poster.email,
                                      ),
                                      // Label(
                                      //   label: "Phone",
                                      //   value: booking.poster.phone,
                                      // ),
                                      Label(
                                        label: "Gender",
                                        value: booking.poster.gender ?? 'N/A',
                                      ),
                                    ]
                                  : [
                                      Label(
                                        label: "Name",
                                        value:
                                            "${booking.ad.agentInfo?["firstName"]} "
                                            "${booking.ad.agentInfo?["lastName"]}",
                                      ),
                                      Label(
                                        label: "Email",
                                        value:
                                            "${booking.ad.agentInfo?["email"]}",
                                      ),
                                      Label(
                                        label: "Phone",
                                        value:
                                            "${booking.ad.agentInfo?["phone"]}",
                                      ),
                                    ],
                            ),
                          ),
                        ),

                      // About client
                      if (booking.isMine && booking.isPayed) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "About client",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],

                      if (booking.isCancelled || booking.isDeclined)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Booking ${booking.status}"),
                        )
                      else ...[
                        if (booking.isMine && booking.isPayed)
                          Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  Label(
                                      label: "Name",
                                      value: booking.client.fullName),
                                  Label(
                                    label: "Country",
                                    value: booking.client.country ?? "N/A",
                                  ),
                                  Label(
                                      label: "Email",
                                      value: booking.client.email),
                                  // Label(
                                  //     label: "Phone",
                                  //     value: booking.client.phone),
                                  Label(
                                    label: "Gender",
                                    value: booking.client.gender ?? "N/A",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (!booking.isMine && booking.isPending)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : controller.cancelBooking,
                              child: const Text(
                                "Cancel booking",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        if (booking.isMine && booking.isPending)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: controller.isLoading.isTrue
                                      ? null
                                      : controller.declineBooking,
                                  child: const Text(
                                    "Decline",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),

                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: controller.isLoading.isTrue
                                      ? null
                                      : controller.acceptBooking,
                                  child: const Text(
                                    "Accept",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              // if (!booking.isMine) const SizedBox(width: 20),
                            ],
                          ),
                        if (booking.isPayed)
                          SizedBox(
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
                                      if (booking.isMine) {
                                        controller.chatWithClient();
                                      } else {
                                        controller.chatWithLandlord();
                                      }
                                    },
                              child: booking.isMine
                                  ? const Text(
                                      "Chat with Client",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Chat with Landlord",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        if (!booking.isMine &&
                            booking.isOffered &&
                            !booking.isPayed)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(96, 15, 116, 1),
                              ),
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : controller.payRent,
                              child: const Text(
                                "Pay rent",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      if (controller.booking.ad.images.isNotEmpty)
                        GridView.count(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 370 ? 4 : 2,
                          crossAxisSpacing: 10,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: booking.ad.images
                              .map(
                                (e) => GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => ViewImages(
                                        images: booking.ad.images
                                            .map((e) =>
                                                CachedNetworkImageProvider(e))
                                            .toList(),
                                        initialIndex:
                                            booking.ad.images.indexOf(e),
                                      ),
                                      transition: Transition.zoom,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 2.5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LoadingProgressImage(
                                        image: CachedNetworkImageProvider(e),
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }),
            if (controller.isLoading.isTrue) const LinearProgressIndicator(),
          ],
        );
      }),
    );
  }
}
