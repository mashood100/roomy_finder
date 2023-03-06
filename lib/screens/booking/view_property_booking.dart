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
// import 'package:roomy_finder/screens/booking/pay_property_booking.dart';
import 'package:roomy_finder/screens/messages/chat.dart';

class _ViewPropertyBookingScreenController extends LoadingController {
  Future<void> acceptBooking(PropertyBooking booking) async {
    final shouldContinue = await showConfirmDialog(
      "Do you really want to accept this ad",
    );
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

  Future<void> cancelBooking(PropertyBooking booking) async {
    final shouldContinue = await showConfirmDialog(
      "Do you really want to decline this booking",
    );
    if (shouldContinue != true) return;
    try {
      isLoading(true);
      final res = await ApiService.getDio
          .post("/bookings/property-ad/${booking.id}/cancel");

      if (res.statusCode == 200) {
        showConfirmDialog(
          "Booking cancelled successfully.",
          isAlert: true,
        );
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

  void payRent(PropertyBooking booking) {
    // Get.to(() => PayProperyBookingScreen(booking: booking));
  }

  Future<void> chatWithClient(PropertyBooking booking) async {
    final conv = (await ChatConversation.getSavedChat(
            ChatConversation.createConvsertionKey(
                AppController.me.id, booking.client.id))) ??
        ChatConversation.newConversation(friend: booking.client);
    Get.to(() => ChatScreen(conversation: conv));
  }

  Future<void> chatWithLandlord(PropertyBooking booking) async {
    final conv = (await ChatConversation.getSavedChat(
            ChatConversation.createConvsertionKey(
                AppController.me.id, booking.poster.id))) ??
        ChatConversation.newConversation(friend: booking.poster);
    Get.to(() => ChatScreen(conversation: conv));
  }
}

class ViewPropertyBookingScreen extends StatelessWidget {
  const ViewPropertyBookingScreen({super.key, required this.booking});
  final PropertyBooking booking;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ViewPropertyBookingScreenController());
    return Scaffold(
      appBar: AppBar(title: const Text('View booking')),
      body: Obx(() {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    if (!booking.isMine)
                      if (booking.isPending || !booking.isPayed)
                        const Alert(
                          text:
                              "You will see the full Landlord information after "
                              "he have accepted the booking and you have paid rent.",
                        ),
                    const Text(
                      "About booking",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Label(label: "Property", value: booking.ad.type),
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
                    Label(label: "Status", value: booking.status),
                    if (booking.status == 'offered')
                      Label(
                        label: "Payment status",
                        value: booking.isPayed ? 'Paid' : "Payment requiry",
                      ),
                    if (!booking.isMine) ...[
                      const Text(
                        "About Landlond",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Label(label: "Name", value: booking.poster.fullName),
                      Label(label: "Country", value: booking.poster.country),
                    ] else ...[
                      const Text(
                        "About client",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Label(label: "Name", value: booking.client.fullName),
                      Label(label: "Country", value: booking.client.country),
                    ],
                    if (!booking.isMine &&
                        booking.isOffered &&
                        booking.isPayed) ...[
                      Label(label: "Email", value: booking.poster.email),
                      Label(label: "Phone", value: booking.poster.phone),
                      Label(label: "Gender", value: booking.poster.gender),
                    ] else if (booking.isMine) ...[
                      Label(label: "Email", value: booking.client.email),
                      Label(label: "Phone", value: booking.client.phone),
                      Label(label: "Gender", value: booking.client.gender),
                    ],
                    const Divider(height: 20),
                    if (booking.isMine && !booking.isOffered)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (booking.isMine)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : () => controller.cancelBooking(booking),
                                child: const Text("Decline"),
                              ),
                            ),
                          if (booking.isMine) const SizedBox(width: 20),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: controller.isLoading.isTrue
                                  ? null
                                  : () => controller.acceptBooking(booking),
                              child: const Text("Accept"),
                            ),
                          ),
                          // if (!booking.isMine) const SizedBox(width: 20),
                        ],
                      ),
                    if (!booking.isMine && !booking.isOffered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : () => controller.cancelBooking(booking),
                          child: const Text("Cancel Booking"),
                        ),
                      ),
                    if (booking.isOffered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                              ? const Text("Chat Client")
                              : const Text("Chat Owner"),
                        ),
                      ),
                    if (!booking.isMine &&
                        booking.isOffered &&
                        !booking.isPayed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.isTrue
                              ? null
                              : () => controller.payRent(booking),
                          child: const Text("Pay rent"),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ...booking.ad.images
                        .map(
                          (e) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(
                                e,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, e, trace) {
                                  return const SizedBox(
                                    width: double.infinity,
                                    height: 150,
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (controller.isLoading.isTrue) const LinearProgressIndicator(),
          ],
        );
      }),
    );
  }
}
