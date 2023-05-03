import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/components/alert.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/booking/pay_property_booking.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';
import 'package:roomy_finder/utilities/data.dart';

class _ViewPropertyBookingScreenController extends LoadingController {
  final PropertyBooking booking;

  _ViewPropertyBookingScreenController(this.booking);

  Future<void> acceptBooking(PropertyBooking booking) async {
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

  Future<void> declineBooking(PropertyBooking booking) async {
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
        showConfirmDialog(
          "Booking cancelled successfully.",
          isAlert: true,
        );
        booking.status = 'declined';
        update();
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

  Future<void> cancelBooking(PropertyBooking booking) async {
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

  Future<void> payRent(PropertyBooking booking) async {
    await Get.to(() => PayProperyBookingScreen(booking: booking));

    update();
  }

  Future<void> chatWithClient(PropertyBooking booking) async {
    final conv = ChatConversation(other: booking.client.chatUser);
    Get.to(() {
      return FlyerChatScreen(
        conversation: conv,
        myId: AppController.me.id,
        otherId: booking.client.id,
      );
    });
  }

  Future<void> chatWithLandlord(PropertyBooking booking) async {
    final conv = ChatConversation(other: booking.poster.chatUser);
    Get.to(() {
      return FlyerChatScreen(
        conversation: conv,
        myId: AppController.me.id,
        otherId: booking.client.id,
      );
    });
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
        backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
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
                      if (!booking.isPayed)
                        Alert(
                          text: booking.isMine
                              ? "You will see the tenant information after "
                                  "you have accepted the booking and he paid the rent."
                              : "You will see the landlord information after "
                                  "he have accepted the booking and you have paid rent.",
                          severity: Severity.info,
                        ),
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
                                value: Jiffy(booking.createdAt).yMMMEd,
                              ),
                              Label(
                                label: "Check In",
                                value: Jiffy(booking.checkIn).yMMMEd,
                              ),
                              Label(
                                label: "Check Out",
                                value: Jiffy(booking.checkOut).yMMMEd,
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
                                  label: "Appartment number",
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
                                        value: booking.poster.country,
                                      ),
                                      Label(
                                        label: "Email",
                                        value: booking.poster.email,
                                      ),
                                      Label(
                                        label: "Phone",
                                        value: booking.poster.phone,
                                      ),
                                      Label(
                                        label: "Gender",
                                        value: booking.poster.gender,
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
                                    value: booking.client.country),
                                Label(
                                    label: "Email",
                                    value: booking.client.email),
                                Label(
                                    label: "Phone",
                                    value: booking.client.phone),
                                Label(
                                    label: "Gender",
                                    value: booking.client.gender),
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
                                : () {
                                    controller.cancelBooking(booking);
                                  },
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
                                    : () => controller.declineBooking(booking),
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
                                    : () => controller.acceptBooking(booking),
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
                                      controller.chatWithClient(booking);
                                    } else {
                                      controller.chatWithLandlord(booking);
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
                                : () => controller.payRent(booking),
                            child: const Text(
                              "Pay rent",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
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
                                    showModalBottomSheet(
                                      context: Get.context!,
                                      builder: (context) {
                                        return CachedNetworkImage(imageUrl: e);
                                      },
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
                                      child: CachedNetworkImage(
                                        imageUrl: e,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorWidget: (ctx, e, trace) {
                                          return const SizedBox(
                                            width: double.infinity,
                                            height: 150,
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 50,
                                            ),
                                          );
                                        },
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) {
                                          return CircularProgressIndicator(
                                            value: downloadProgress.progress,
                                          );
                                        },
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
