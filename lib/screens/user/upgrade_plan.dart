import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class _UpgradePlanController extends LoadingController {
  Future<void> upgradePlan() async {
    try {
      isLoading(true);
      await Future.delayed(const Duration(seconds: 5));
      showConfirmDialog(
        "Service temporally unavailable. Please try again later",
        isAlert: true,
      );
    } catch (e) {
      Get.log("$e");
      showConfirmDialog("someThingWentWrong".tr, isAlert: true);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _payRent(String service) async {
    try {
      isLoading(true);
      switch (service) {
        case "STRIPE":
        case "PAYPAL":
          await showConfirmDialog(
            "You will need to logout and then login back after completing the payment",
            isAlert: true,
          );
          final String endPoint;

          if (service == "STRIPE") {
            endPoint = "/profile/upgrade-plan/stripe";
          } else if (service == "PAYPAL") {
            endPoint = "/profile/upgrade-plan/paypal";
          } else {
            return;
          }
          // 1. create payment intent on the server
          final res = await ApiService.getDio.post(
            endPoint,
          );

          if (res.statusCode == 409) {
            showToast("Already premium");
            AppController.instance.user.update((val) {
              if (val != null) val.isPremium = true;
            });
            Get.back();
          } else if (res.statusCode == 200) {
            showToast("Payment initiated. Redirecting....");
            isLoading(false);

            final uri = Uri.parse(res.data["paymentUrl"]);

            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            showConfirmDialog("Something when wrong", isAlert: true);
            Get.log("${res.data}}");
            return;
          }

          break;

        case "ROOMY_FINDER_CARD":
          showGetSnackbar("Payment with Roomy Finder can is comming soon!");
          break;
        case "PAY_CASH":
          final result = await showConfirmDialog(
            "Please confirm that you want to pay cash to the landlord",
          );
          if (result == true) {
            final res = await ApiService.getDio.post(
              "/bookings/property-ad/pay-cash",
            );

            if (res.statusCode == 200) {
              await showConfirmDialog(
                "Congratulations. You can now see the landlord information",
                isAlert: true,
              );
              Get.back(result: true);
            } else {
              showConfirmDialog("Something when wrong", isAlert: true);
              Get.log("${res.data}}");
            }
          }
          break;
        default:
      }
    } catch (e, trace) {
      showGetSnackbar("Something went wrong", severity: Severity.error);
      Get.log('$trace');
    } finally {
      isLoading(false);
    }
  }
}

class UpgragePlanScreen extends StatelessWidget {
  const UpgragePlanScreen({super.key, this.skipCallback});
  final void Function()? skipCallback;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_UpgradePlanController());
    return Scaffold(
      appBar: AppBar(title: const Text("Upgrade plan")),
      body: Obx(() {
        return Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset("assets/images/premium.png"),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        "Pay 250 AED to upgrade to premium",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              controller._payRent("STRIPE");
                            },
                            icon: const Icon(Icons.credit_card),
                            label: const Text("Pay with Credit or Debit card "),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              controller._payRent("PAYPAL");
                            },
                            icon: const Icon(Icons.paypal, color: Colors.blue),
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
                  ),
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
