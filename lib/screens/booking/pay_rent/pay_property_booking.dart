import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:url_launcher/url_launcher.dart';

class _PayPropertyBookingController extends LoadingController {
  final PropertyBooking booking;

  _PayPropertyBookingController(this.booking);

  Future<void> _payRent(String service) async {
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
            showConfirmDialog("Something when wrong", isAlert: true);
            Get.log("${res.data}}");
            return;
          }

          break;

        case "ROOMY_FINDER_CARD":
          showGetSnackbar("Payment with Roomy Finder Card is comming soon!");
          break;
        case "PAY_CASH":
          final result = await showConfirmDialog(
            "Please confirm that you want to pay cash to the landlord",
          );
          if (result == true) {
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PayPropertyBookingController(booking));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deposit page"),
        backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      ),
      body: Obx(() {
        return Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset("assets/images/premium.png"),
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      "Payment details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Label(
                            label: "Property & quantity",
                            value: "${booking.quantity} ${booking.ad.type}"
                                "${booking.quantity > 1 ? "s" : ""}",
                            fontSize: 16,
                          ),
                          Label(
                            label: "Rent type",
                            value: booking.rentType,
                            fontSize: 16,
                          ),
                          Label(
                            label: "Rent period",
                            value:
                                "${booking.rentPeriod} ${booking.rentPeriodUnit} "
                                "${booking.rentPeriod > 1 ? "s" : ""}",
                            fontSize: 16,
                          ),
                          Obx(() {
                            return Label(
                              label: "Total Rent fee",
                              value: formatMoney(
                                (booking.rentFee + booking.commissionFee) *
                                    AppController.instance.country.value
                                        .aedCurrencyConvertRate *
                                    5,
                              ),
                              fontSize: 16,
                            );
                          }),
                          Label(
                            label: "VAT",
                            value: "(5%)  ${formatMoney(
                              booking.vatFee *
                                  AppController.instance.country.value
                                      .aedCurrencyConvertRate,
                            )}",
                            fontSize: 16,
                          ),
                          Label(
                            label: "Service fee",
                            value: "(3%)  ${formatMoney(
                              booking.calculateFee(0.03) *
                                  AppController.instance.country.value
                                      .aedCurrencyConvertRate,
                            )}",
                            fontSize: 16,
                          ),
                          Builder(builder: (context) {
                            return Label(
                              label: "Total",
                              value: formatMoney(
                                (booking.rentFee +
                                        booking.commissionFee +
                                        booking.vatFee +
                                        booking.calculateFee(0.03)) *
                                    AppController.instance.country.value
                                        .aedCurrencyConvertRate,
                              ),
                              fontSize: 20,
                              boldLabel: true,
                              boldValue: true,
                            );
                          }),
                          const Divider(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller._payRent("STRIPE");
                              },
                              icon: const Icon(Icons.credit_card),
                              label:
                                  const Text("Pay with Credit or Debit card "),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller._payRent("PAYPAL");
                              },
                              icon:
                                  const Icon(Icons.paypal, color: Colors.blue),
                              label: const Text("Pay with PayPal"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller._payRent("ROOMY_FINDER_CARD");
                              },
                              icon: const Icon(
                                Icons.credit_card,
                                color: Color.fromRGBO(96, 15, 116, 1),
                              ),
                              label: const Text("Pay with RoomyFinder card"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller._payRent("PAY_CASH");
                              },
                              icon: const Icon(Icons.payments_rounded),
                              label: const Text("Pay Cash at property"),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (controller.isLoading.isTrue)
              Card(
                color: Colors.purple.withOpacity(0.5),
                child: Container(
                  alignment: Alignment.center,
                  height: 200,
                  width: 200,
                  child: const CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 30,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
