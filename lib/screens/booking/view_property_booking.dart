import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/image_grid.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/utility_screens/value_sector.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class _ViewPropertyBookingScreenController extends LoadingController {
  final PropertyBooking booking;

  _ViewPropertyBookingScreenController(this.booking);

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> fcmStream;

  ({String asset, String label, String value})? _paymentService;

  static const _paymentOptions = [
    (
      label: "Pay by Card",
      value: "STRIPE",
      asset: AssetImages.visaMasterCardPNG,
    ),
    (
      label: "Pay with PayPal",
      value: "PAYPAL",
      asset: AssetImages.paypalBookingPNG,
    ),
    (
      label: "Pay by Cash",
      value: "PAY CASH",
      asset: AssetIcons.dollarBanknotePNG,
    ),
  ];

  @override
  void onInit() {
    super.onInit();

    switch (booking.paymentService) {
      case 'STRIPE':
        _paymentService = _paymentOptions[0];
        break;
      case 'PAYPAL':
        _paymentService = _paymentOptions[1];
        break;
      case 'PAY CASH':
        _paymentService = _paymentOptions[2];
        break;
      default:
    }

    _markBookingAsViewed();

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
      final b = await ApiService.fetchBooking(data["bookingId"].toString());
      if (b == null) return;

      booking.updateFrom(b);

      _markBookingAsViewed();

      switch (data["event"]) {
        case "booking-offered":
          showToast("Booking offered");

          break;
        case "booking-declined":
          await showConfirmDialog(
            "This booking have just been declined by landlord",
            isAlert: true,
          );

          break;
        case "booking-cancelled":
          await showConfirmDialog(
            "This booking have just been cancelled",
            isAlert: true,
          );
          // Get.back();

          break;
        case "pay-property-rent-fee-paid-cash":
        case "pay-property-rent-fee-completed-client":
        case "pay-property-rent-fee-completed-landlord":
          showToast("Booking paid");

          break;

        default:
      }

      update();
    });
  }

  @override
  void onClose() {
    super.onClose();
    fcmStream.cancel();

    _fGBGNotifierSubScription.cancel();

    if (booking.isMine) {
      booking.isViewedByLandlord = true;
    } else {
      booking.isViewedByClient = true;
    }
    ApiService.setUnreadBookingCount();
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
        if (booking.paymentService == "PAY CASH") booking.isPayed = true;
        update();
      } else if (res.statusCode == 404) {
        showConfirmDialog(
          "Booking not found",
          isAlert: true,
        );
      } else {
        Get.log(res.statusCode.toString());
        showConfirmDialog(
          "Something went wrong. Please try again later",
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
      } else if (res.statusCode == 404) {
        showConfirmDialog(
          "Booking not found",
          isAlert: true,
        );
      } else {
        Get.log(res.statusCode.toString());
        showGetSnackbar(
          "Something went wrong. Please try again later",
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
        "/bookings/property-ad/cancel",
        data: {'bookingId': booking.id},
      );

      if (res.statusCode == 200) {
        booking.status = "cancelled";
        if (booking.poster.isMe) {
          booking.cancelMessage = "Cancelled by landlord";
        } else {
          booking.cancelMessage = "Cancelled by tenant";
        }
        isLoading(false);
        update();

        await showConfirmDialog(
          "Booking cancelled",
          isAlert: true,
        );
      } else if (res.statusCode == 400) {
        showToast(
          res.data["message"]?.toString() ?? "Can't cancel booking now",
          severity: Severity.error,
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

      update();
    }
  }

  Future<void> changePaymentMethod() async {
    var result = await Get.to(
      () {
        return ValueSelctorScreen(
          title: 'Select payment method',
          data: _paymentOptions,
          currentValue: _paymentService,
          getLabel: (item) => item.label,
          leadingBuilder: (item) => Image.asset(
            item.asset,
            height: 30,
            width: 100,
            color: item.value == "PAY CASH" ? Colors.green : null,
          ),
          confirmButtonText: "Confirm",
        );
      },
    );

    if (result == null) return;

    _paymentService = result;
    booking.paymentService = _paymentService?.value;

    update();

    _payRent();
  }

  Future<void> _payRent() async {
    if (_paymentService == null) {
      showToast("Please choose payment method");
      return;
    }
    String service = _paymentService!.value;

    try {
      isLoading(true);
      switch (service) {
        case "STRIPE":
        case "PAYPAL":
          final String endPoint;

          if (service == "STRIPE") {
            endPoint =
                "/bookings/property-ad/stripe/create-pay-booking-checkout-session";
          } else if (service == "PAYPAL") {
            endPoint = "/bookings/property-ad/paypal/create-payment-link";
          } else {
            return;
          }
          // 1. create payment intent on the server
          final res = await ApiService.getDio.post(
            endPoint,
            data: {"bookingId": booking.id},
          );

          if (res.statusCode == 409) {
            showToast("Rent already paid");
            booking.isPayed = true;
          } else if (res.statusCode == 200) {
            showToast("Payment initiated. Redirecting....");
            isLoading(false);

            final uri = Uri.parse(res.data["paymentUrl"]);

            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            showConfirmDialog("Something went wrong", isAlert: true);
            Get.log("${res.data}}");
            return;
          }

          break;

        case "ROOMY_FINDER_CARD":
          showGetSnackbar("Payment with Roomy Finder Card is comming soon!");
          break;
        case "PAY CASH":
          final res = await ApiService.getDio.post(
            "/bookings/property-ad/pay-cash",
            data: {"bookingId": booking.id},
          );
          if (res.statusCode == 200) {
            showToast("Booking paid cash successfully");
            booking.isPayed = true;

            return;
          } else if (res.statusCode == 409) {
            showToast("Booking already paid");
            booking.isPayed = true;
          } else {
            showToast("Something went wrong");
            Get.log("${res.data}}");
          }
          break;
        default:
      }
    } catch (e) {
      showToast("Something went wrong");
      Get.log('Error: $e');
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> _markBookingAsViewed() async {
    try {
      if (booking.isViewedByLandlord && booking.isMine) return;
      if (booking.isViewedByClient && !booking.isMine) return;

      final res = await ApiService.getDio.get(
        "/bookings/property-ad/${booking.id}/mark-booking-as-view",
      );

      if (res.statusCode == 200) {
        if (booking.isMine) {
          booking.isViewedByLandlord = true;
        } else {
          booking.isViewedByClient = true;
        }
        ApiService.setUnreadBookingCount();
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
  const ViewPropertyBookingScreen({super.key, required this.b});
  final PropertyBooking b;

  bool get _canCancelBooking {
    if (!["active", "pending", "offered"].contains(b.status)) {
      return false;
    }
    if (b.isMine && b.isPending) return false;

    return b.checkIn.add(const Duration(days: 1)).isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ViewPropertyBookingScreenController(b));

    var canSeeDetails = !b.isPending && !b.isCancelled && !b.isDeclined;

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
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // About booking
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.asset(
                        AssetIcons.calenderPNG,
                        height: 30,
                      ),
                      title: const Text(
                        "Booking Details",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        (
                          label: "Property",
                          value: b.ad.type,
                        ),
                        if (b.isPayed)
                          (
                            label: "Property location",
                            value: "${b.ad.city}, ${b.ad.location}",
                          ),
                        (
                          label: "Quantity ",
                          value: "${b.quantity}",
                        ),
                        (
                          label: "Booking date",
                          value: Jiffy.parseFromDateTime(b.createdAt)
                              .toLocal()
                              .yMMMd,
                        ),
                        (
                          label: "Check In",
                          value: Jiffy.parseFromDateTime(b.checkIn)
                              .toLocal()
                              .yMMMd,
                        ),
                        (
                          label: "Check Out",
                          value: Jiffy.parseFromDateTime(b.checkOut)
                              .toLocal()
                              .yMMMd,
                        ),
                        (
                          label: "Payment method",
                          value: controller._paymentService?.label ?? "N/A",
                        ),
                        (
                          label: "Status",
                          value: b.capitaliezedStatus,
                        ),
                        if (b.cancelMessage != null)
                          (
                            label: "Note",
                            value: b.cancelMessage!,
                          ),
                        if (b.isOffered)
                          (
                            label: "Payment status",
                            value: b.isPayed ? 'Paid' : "Payment required",
                          ),
                      ].map((e) {
                        Color? valueColor;
                        if (e.label == "Status") {
                          valueColor = b.isOffered
                              ? Colors.green
                              : b.isPending
                                  ? Colors.blue
                                  : Colors.red;
                          if (b.isActive) valueColor = Colors.green;
                        }
                        return _Label(
                          label: e.label,
                          value: e.value,
                          valueColor: valueColor,
                        );
                      }).toList(),
                    ),
                    const Divider(),

                    // About property
                    if (canSeeDetails)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              AssetIcons.homePNG,
                              height: 30,
                            ),
                            title: const Text(
                              "About property",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...[
                            (
                              label: "Property",
                              value: b.ad.type,
                            ),
                            (
                              label: "Property location",
                              value: "${b.ad.city}, ${b.ad.location}",
                            ),
                            (
                              label: "Building",
                              value: b.ad.address['buildingName'] ?? "N/A",
                            ),
                            (
                              label: "Apartment number",
                              value: b.ad.address['appartmentNumber'] ?? "N/A",
                            ),
                            (
                              label: "Floor number",
                              value: b.ad.address['floorNumber'] ?? "N/A",
                            ),
                          ].map((e) => _Label(label: e.label, value: e.value)),
                          const Divider(),
                        ],
                      ),

                    // About Landlord
                    if (canSeeDetails && !b.isMine)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              AssetIcons.personPNG,
                              height: 30,
                            ),
                            title: const Text(
                              "About Landlord",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...[
                            (
                              label: "Name",
                              value: b.poster.fullName,
                            ),
                            (
                              label: "Nationality",
                              value: b.poster.country ?? "N/A",
                            ),
                            (
                              label: "Gender",
                              value: b.poster.gender ?? "N/A",
                            ),
                          ].map((e) => _Label(label: e.label, value: e.value)),
                          const Divider(),
                        ],
                      ),

                    // About tenant
                    if ((b.isActive || b.isPending || b.isOffered) && b.isMine)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              AssetIcons.personPNG,
                              height: 30,
                            ),
                            title: const Text(
                              "About Tenant",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...[
                            (
                              label: "Name",
                              value: b.client.fullName,
                            ),
                            (
                              label: "Nationality",
                              value: b.client.country ?? "N/A",
                            ),
                            (
                              label: "Gender",
                              value: b.client.gender ?? "N/A",
                            ),
                          ].map((e) => _Label(label: e.label, value: e.value)),
                          const Divider(),
                        ],
                      ),

                    // Agent / Broker
                    if (b.ad.posterType != "Landlord" && canSeeDetails)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              AssetIcons.personPNG,
                              height: 30,
                            ),
                            title: const Text(
                              "Agent/Broker Details",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...[
                            (
                              label: "first name",
                              value: b.ad.agentInfo?["firstName"] ?? "N/A",
                            ),
                            (
                              label: "Last name",
                              value: b.ad.agentInfo?["lastName"] ?? "N/A",
                            ),
                            // (
                            //   label: "Email",
                            //   value: booking.ad.agentInfo?["email"] ?? "N/A",
                            // ),
                            // (
                            //   label: "Phone",
                            //   value: booking.ad.agentInfo?["phone"] ?? "N/A",
                            // ),
                          ].map((e) => _Label(label: e.label, value: e.value)),
                          const Divider(height: 20),
                        ],
                      ),

                    if (b.isActive || b.isOffered) ...[
                      CustomButton(
                        b.isMine ? "Chat with tenant" : "Chat with landlord",
                        width: double.infinity,
                        onPressed: () {
                          if (b.isMine) {
                            controller.chatWithClient();
                          } else {
                            controller.chatWithLandlord();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_canCancelBooking) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: controller.cancelBooking,
                          child: const Text("Cancel booking"),
                        ),
                      ),
                      const SizedBox(height: 10)
                    ],

                    if (b.isPending && b.isMine) ...[
                      const Center(
                        child: Text(
                          "Do you accept this booking?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        var list = [
                          (
                            label: "Accept",
                            onPressed: controller.acceptBooking,
                            bColor: Colors.green,
                          ),
                          null,
                          (
                            label: "Decline",
                            onPressed: controller.declineBooking,
                            bColor: Colors.red,
                          ),
                        ];

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: list.map(
                            (e) {
                              if (e == null) return const SizedBox(width: 10);
                              return Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(width: 2, color: e.bColor),
                                  ),
                                  onPressed: e.onPressed,
                                  child: Text(
                                    e.label,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        );
                      }),
                      const Divider(height: 20),
                    ],

                    if (b.isOffered && !b.isMine && !b.isPayed) ...[
                      CustomButton(
                        "Change payment method",
                        width: double.infinity,
                        onPressed: controller.changePaymentMethod,
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        controller._paymentService != null
                            ? "Confirm"
                            : "Please select payment method",
                        width: double.infinity,
                        onPressed: () {
                          if (controller._paymentService == null) {
                            controller.changePaymentMethod();
                          } else {
                            controller._payRent();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    ImageGrid(
                      items: b.ad.images,
                      getImage: (item) => CachedNetworkImageProvider(item),
                      noDataMessage: "No images",
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            }),
            if (controller.isLoading.isTrue) const LoadingPlaceholder(),
          ],
        );
      }),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    this.value,
    this.valueColor,
  });

  final String label;
  final dynamic value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
