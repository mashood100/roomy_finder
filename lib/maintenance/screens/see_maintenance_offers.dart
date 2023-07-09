import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class SeeMaintenanceOffersScreen extends StatefulWidget {
  const SeeMaintenanceOffersScreen({super.key, required this.request});
  final Maintenance request;

  @override
  State<SeeMaintenanceOffersScreen> createState() =>
      _SeeMaintenanceOffersScreenState();
}

class _SeeMaintenanceOffersScreenState
    extends State<SeeMaintenanceOffersScreen> {
  List<Map<String, dynamic>> get _offers => widget.request.offers;

  bool _isLoading = false;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> fcmStream;

  @override
  void initState() {
    super.initState();

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        final newM = await ApiService.fetchMaitenance(widget.request.id);

        if (newM != null) {
          widget.request.updateFrom(newM);
          setState(() {});
        }
      }
    });

    fcmStream =
        FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;

      switch (data["event"]) {
        case "maintenance-offer-new":
        case "maintenance-offer-submit":
        case "maintenance-paid-successfully":
          if (widget.request.id != data["maintenanceId"]) return;

          final newM = await ApiService.fetchMaitenance(m.id);
          if (newM == null) return;

          switch (data["event"]) {
            case "maintenance-offer-new":
              setState(() => m.offers = newM.offers);
              showToast("New Maintenance offer");
              break;
            case "maintenance-offer-submit":
              setState(() => m.submits = newM.submits);
              showToast("New Maintenance submit");
              break;
            case "maintenance-paid-successfully":
              setState(() => m.isPaid = newM.isPaid);
              break;
          }

          break;

        default:
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _fGBGNotifierSubScription.cancel();
    fcmStream.cancel();
  }

  Maintenance get m => widget.request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Maintenance's offers")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: _offers.isEmpty
                ? const Center(child: Text("No data"))
                : Column(
                    children: _offers.map((e) {
                    final createdAt = DateTime.parse(e["createdAt"] as String);
                    final totalPrice = (e["tasks"] as List)
                        .map((e) => (e as Map)["budget"] as num)
                        .reduce((val, e) => val + e);
                    final formattedPrice =
                        formatMoney(totalPrice * AppController.convertionRate);

                    final user = User.fromMap(e["user"]);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Price : $formattedPrice",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    "Date : ${Jiffy.parseFromDateTime(createdAt).yMMMEdjm}"),
                                Text("Maintenant : ${user.fullName}"),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      height: 35,
                                      child: TextButton(
                                        onPressed: _isLoading ||
                                                widget.request.status !=
                                                    "Pending" ||
                                                e["status"] != "Pending"
                                            ? null
                                            : () => payMentanceFee(
                                                  widget.request,
                                                  e,
                                                ),
                                        child: Text(
                                          e["status"] == "Accepted"
                                              ? "Accepted"
                                              : "Pay & Accept",
                                          style: e["status"] == "Accepted"
                                              ? const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 35,
                                      child: TextButton(
                                        onPressed: _isLoading ||
                                                widget.request.status !=
                                                    "Pending" ||
                                                e["status"] != "Pending"
                                            ? null
                                            : () => _handleRejectPressed(e),
                                        child: Text(
                                          e["status"] == "Rejected"
                                              ? "Rejected"
                                              : "Reject",
                                          style: e["status"] == "Rejected"
                                              ? const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 35,
                                      child: TextButton(
                                        onPressed: () =>
                                            _handleDetailsPressed(e),
                                        child: const Text("Details"),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            user.ppWidget(size: 30),
                          ],
                        ),
                      ),
                    );
                  }).toList()),
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  // void _handleAcceptPressed(Map<String, dynamic> offer) async {
  //   try {
  //     final confirm = await showConfirmDialog("Please confirm");

  //     if (confirm != true) return;

  //     setState(() => _isLoading = true);

  //     final res = await ApiService.getDio.post(
  //       '/maintenances/${widget.request.id}/accept-offer',
  //       data: {
  //         "maintenantId": offer["user"]["id"],
  //         "offerId": offer["id"],
  //       },
  //     );

  //     if (res.statusCode == 200) {
  //       showToast("Operation completed");
  //       setState(() {
  //         widget.request.status = "Offered";
  //         offer["status"] = "Accepted";
  //       });
  //     } else {
  //       showToast("Operation failed. Please try again later");
  //     }
  //   } catch (e) {
  //     showToast("Operation failed. Please try again later");
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  void _handleRejectPressed(Map<String, dynamic> offer) async {
    try {
      final confirm = await showConfirmDialog("Please confirm");

      if (confirm != true) return;

      setState(() => _isLoading = true);

      final res = await ApiService.getDio.post(
        '/maintenances/${widget.request.id}/decline-offer',
        data: {
          "maintenantId": offer["user"]["id"],
          "offerId": offer["id"],
        },
      );

      if (res.statusCode == 200) {
        showToast("Operation completed");
        setState(() => offer["status"] = "Rejected");
      } else {
        showToast("Operation failed. Please try again later");
      }
    } catch (e) {
      showToast("Operation failed. Please try again later");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleDetailsPressed(Map<String, dynamic> offer) {
    final totalPrice = (offer["tasks"] as List)
        .map((e) => (e as Map)["budget"] as num)
        .reduce((val, e) => val + e);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        var formatMoney2 =
            formatMoney(totalPrice * AppController.convertionRate);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Total Price : $formatMoney2",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Divider(),
                  ...(offer['tasks'] as List).map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${e["name"]} (${widget.request.getQuantity(e["name"])})",
                                ),
                              ),
                              const Text(
                                "Material Included",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatMoney(
                                    e["budget"] * AppController.convertionRate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                e["materialIncluded"] == true ? "Yes" : "No",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: e["materialIncluded"] == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              )
                            ],
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: Get.back,
                      child: const Text("OK"),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> payMentanceFee(Maintenance m, Map<String, dynamic> offer) async {
  final context = Get.context;

  if (context == null) return;

  final String message;

  if (m.paymentMethod == "CASH") {
    message = "The payment method for this maintenance is CASH."
        " You have to pay a 10% commission fee plus the VAT."
        " Please choose payment method";
  } else {
    message = "Please choose payment method";
  }

  final paymentMethod = await showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text("Maintenance"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("STRIPE"),
            onPressed: () => Get.back(result: "STRIPE"),
          ),
          CupertinoDialogAction(
            child: const Text("PAYPAL"),
            onPressed: () => Get.back(result: "PAYPAL"),
          ),
          CupertinoDialogAction(
            child: const Text("CANCEL"),
            onPressed: () => Get.back(),
          ),
        ],
      );
    },
  );

  if (paymentMethod == null) return;

  try {
    final String endPoint = "/maintenances/${m.id}/pay-maintenance";

    final res = await ApiService.getDio.post(
      endPoint,
      data: {
        "paymentMethod": paymentMethod,
        "offerId": offer["id"],
      },
    );

    if (res.statusCode == 503) {
      showToast("$paymentMethod Service temporally unavailable");
      return;
    } else if (res.statusCode == 403) {
      showToast(res.data["message"] ?? "Something when wrong");
    } else if (res.statusCode == 409) {
      showToast("Maintenance already paid");
      m.isPaid = true;
    } else if (res.statusCode == 200) {
      showToast("Payment initiated. Redirecting....");

      final uri = Uri.parse(res.data["paymentUrl"]);

      if (await canLaunchUrl(uri)) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showToast("Failed to open payment link. Please install a browser");
      }

      Get.back();
    } else {
      showToast("Something when wrong");
      Get.log("${res.data}}");
      return;
    }
  } catch (e) {
    showToast("Something went wrong");
    showToast('Error: $e');
  }
}
