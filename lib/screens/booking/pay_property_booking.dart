import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class _PayPropertyBookingController extends LoadingController {
  final PropertyBooking booking;
  final _paymentService = "".obs;

  @override
  void onInit() {
    _paymentService.value = booking.paymentService ?? "";
    super.onInit();
  }

  _PayPropertyBookingController(this.booking);

  Future<void> _payRent() async {
    String service = _paymentService.value;

    if (service.isEmpty) {
      showToast("Please choose payament service");
      return;
    }

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
            Get.back();
          } else if (res.statusCode == 200) {
            showToast("Payment initiated. Redirecting....");
            isLoading(false);

            final uri = Uri.parse(res.data["paymentUrl"]);

            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }

            Get.back();
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
            await showConfirmDialog(
              "Congratulations. You can now see the landlord information",
              isAlert: true,
            );
            booking.isPayed = true;
            Get.back(result: true);
            return;
          } else if (res.statusCode == 409) {
            await showConfirmDialog("Booking already paid", isAlert: true);
            booking.isPayed = true;
            Get.back(result: true);
          } else {
            showConfirmDialog("Something when wrong", isAlert: true);
            Get.log("${res.data}}");
          }
          break;
        default:
      }
    } catch (e) {
      showConfirmDialog("Something went wrong", isAlert: true);
      showGetSnackbar('Error: $e');
    } finally {
      isLoading(false);
    }
  }
}

class PayProperyBookingScreen extends StatelessWidget {
  const PayProperyBookingScreen({
    super.key,
    required this.booking,
  });
  final PropertyBooking booking;

  String get _paymentMethod {
    switch (booking.paymentService) {
      case "STRIPE":
        return "Pay by Card";
      case "PAYPAL":
        return "Paypal";
      case "PAY CASH":
        return "Pay by cash";

      default:
        return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PayPropertyBookingController(booking));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking payment"),
        backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      ),
      body: Obx(() {
        return Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property details
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
                          "Property Details",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Label(label: "Property", value: booking.ad.type),
                      Label(
                        label: "Location",
                        value: booking.ad.address["location"],
                      ),
                      Label(
                        label: "Building",
                        value: booking.ad.address["buildingName"],
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // Booking details
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset(
                          AssetIcons.calenderPNG,
                          height: 25,
                        ),
                        title: const Text(
                          "Booking Details",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Label(
                        label: "Quantity booked",
                        value: "${booking.quantity}",
                      ),
                      Label(
                        label: "Booking date",
                        value: Jiffy.parseFromDateTime(booking.createdAt)
                            .toLocal()
                            .yMMMd,
                      ),
                      Label(
                        label: "Check In",
                        value: Jiffy.parseFromDateTime(booking.checkIn)
                            .toLocal()
                            .yMMMd,
                      ),
                      Label(
                        label: "Check Out",
                        value: Jiffy.parseFromDateTime(booking.checkOut)
                            .toLocal()
                            .yMMMd,
                      ),
                      if (controller._paymentService.isNotEmpty)
                        Label(
                          label: "Payment method",
                          value: _paymentMethod,
                        ),
                    ],
                  ),

                  const Divider(height: 40),

                  // Payment details
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset(
                          AssetIcons.payServicePNG,
                          height: 25,
                        ),
                        title: const Text(
                          "Payment Details",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Label(
                        label: "Rent price",
                        value: formatMoney(
                          (booking.rentFee + booking.commissionFee) *
                              AppController.convertionRate,
                        ),
                      ),
                      if (booking.ad.hasDeposit)
                        Label(
                          label: "Deposit fee",
                          value: " ${formatMoney(
                            booking.ad.depositPrice! *
                                booking.quantity *
                                AppController.convertionRate,
                          )}",
                        ),
                      Label(
                        label: "VAT",
                        value: "(5%)  ${formatMoney(
                          booking.vatPercentage * AppController.convertionRate,
                        )}",
                      ),
                      Builder(builder: (context) {
                        final serviceFee = AppController.me.serviceFee ?? 3;
                        return Label(
                          label: "Service fee",
                          value: "($serviceFee%)  ${formatMoney(
                            booking.calculateFee(serviceFee / 100) *
                                AppController.convertionRate,
                          )}",
                        );
                      }),
                      Builder(builder: (context) {
                        final serviceFee = AppController.me.serviceFee ?? 3;
                        var total = booking.rentFee +
                            booking.commissionFee +
                            booking.vatPercentage +
                            booking.calculateFee(serviceFee / 100);
                        if (booking.ad.hasDeposit) {
                          total += booking.ad.depositPrice! * booking.quantity;
                        }
                        return Label(
                          label: "Total",
                          value: formatMoney(
                            (total) * AppController.convertionRate,
                          ),
                        );
                      }),
                      // Label(
                      //   label: "Payment service",
                      //   value: controller._paymentService,
                      // ),
                    ],
                  ),

                  const Divider(height: 40),
                  // Payment method
                  if (controller._paymentService.isEmpty)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Image.asset(
                            AssetIcons.payServicePNG,
                            height: 25,
                          ),
                          title: const Text(
                            "How would you like to pay?",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...[
                          (
                            value: "STRIPE",
                            label: "Credit/Debit Card",
                            asset: AssetImages.visaCardPNG,
                          ),
                          (
                            value: "PAYPAL",
                            label: "PayPal",
                            asset: AssetIcons.paypalPNG
                          ),
                          (
                            value: "PAY CASH",
                            label: "Pay Cash at property",
                            asset: AssetImages.paycashBookingPNG,
                          ),
                          (
                            value: "ROOMY_FINDER_CARD",
                            label: "Pay with RoomyFinder card",
                            asset: AssetIcons.mobilePayPNG,
                          ),
                          // "Mix"
                        ].map((e) {
                          var isSelected =
                              controller._paymentService.value == e.value;
                          return GestureDetector(
                            onTap: () {
                              controller._paymentService(e.value);
                            },
                            child: Container(
                              decoration: shadowedBoxDecoration.copyWith(
                                border: isSelected
                                    ? Border.all(width: 2, color: ROOMY_PURPLE)
                                    : Border.all(width: 1, color: Colors.grey),
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Image.asset(e.asset, width: 40),
                                title: Text(
                                  e.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),

                  CustomButton(
                    "Confirm Payment",
                    onPressed: controller._payRent,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (controller.isLoading.isTrue) const LoadingPlaceholder(),
          ],
        );
      }),
    );
  }
}

class Label extends StatelessWidget {
  const Label({super.key, required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
