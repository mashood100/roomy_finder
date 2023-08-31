import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class PayRoomyBalanceScreen extends StatefulWidget {
  const PayRoomyBalanceScreen({super.key});

  @override
  State<PayRoomyBalanceScreen> createState() => _PayRoomyBalanceScreenState();
}

class _PayRoomyBalanceScreenState extends State<PayRoomyBalanceScreen> {
  var _isLoading = false;
  String? stripeConnectId;

  late final StreamSubscription<RemoteMessage> fcmStream;
  late final PageController _pageController;

  // // Account balance
  // num _amountToWithDraw = 0;
  // String? withdrawMethod;
  // num? _accountBalance;

  // Roomy balance
  num _amountToPay = 0;
  String? paymentmethodMethod;
  num? _roomyBalance;

  final _paypalEmailController = TextEditingController(
    text: AppController.me.email,
  );

  @override
  void initState() {
    fetchAccountDetails();

    _pageController = PageController();

    fcmStream = FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;
      // AppController.instance.haveNewMessage(false);
      switch (data["event"]) {
        case "withdraw-completed":
        case "withdraw-failed":
          fetchAccountDetails();

          break;
        default:
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _paypalEmailController.dispose();
    fcmStream.cancel();
    super.dispose();
  }

  Future<void> fetchAccountDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getDio.get("/profile/account-details");

      if (res.statusCode == 200) {
        final data = res.data;
        stripeConnectId = data["stripeConnectId"];
        _roomyBalance = data["roomyBalance"];
      }
    } catch (e) {
      showToast("Failed to load balance");
      log(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _payRoomyBalance(String service) async {
    final amount = _amountToPay * AppController.convertionRate;
    if (amount < 100) {
      showToast(
        "Amount too small. Minimum is"
        " ${100 * AppController.convertionRate} "
        "${AppController.instance.country.value.currencyCode}",
      );
      return;
    }
    final shouldContinue = await showConfirmDialog("Please confirm");
    if (shouldContinue != true) return;
    try {
      setState(() => _isLoading = true);
      if (!_paypalEmailController.text.isEmail) {
        showToast("Invalid email");
        return;
      }
      final String endPoint;
      final Map data;

      if (service == "STRIPE") {
        endPoint = "/transactions/roomy-balance/stripe/"
            "create-pay-roomy-balance-checkout-session";
        data = {
          "amount": amount,
          "currency": AppController.instance.country.value.currencyCode,
        };
      } else if (service == "PAYPAL") {
        endPoint = "/transactions/payout/paypal/withdraw";
        data = {
          "amount": amount,
          "email": _paypalEmailController.text,
          "currency": AppController.instance.country.value.currencyCode,
        };
      } else {
        return;
      }

      final res = await ApiService.getDio.post(endPoint, data: data);

      if (res.statusCode == 200) {
        showToast("Transaction initiated. Redirecting....");

        final uri = Uri.parse(res.data["paymentUrl"]);
        Get.back();

        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (res.statusCode == 400) {
        showToast(res.data["message"], duration: 10);
      } else if (res.statusCode == 403) {
        showToast("Insufficient balance");
      } else {
        showConfirmDialog("Failed to initiate transaction", isAlert: true);
        Get.log("${res.data}}");
        return;
      }
    } catch (e, trace) {
      showToast("Something went wrong", severity: Severity.error);
      Get.log('$trace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Roomy Pay")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Roomy balance",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _roomyBalance != null ? formatMoney(_roomyBalance!) : "???",
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Amount",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InlineTextField(
                hintText: "How much to pay",
                suffixText: AppController.instance.country.value.currencyCode,
                enabled: !_isLoading,
                onChanged: (value) {
                  if (value.isEmpty) {
                    _amountToPay = 0;
                  } else {
                    _amountToPay = num.parse(value);
                  }
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                "Please choose your payment method:",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  (
                    value: "STRIPE",
                    label: "Credit/Debit Card",
                    asset: AssetImages.visaCardPNG,
                  ),
                  (
                    value: "PAYPAL",
                    label: "PayPal",
                    asset: AssetIcons.paypalPNG,
                  ),
                  // "Mix"
                ].map((e) {
                  var isSelected = paymentmethodMethod == e.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() => paymentmethodMethod = e.value);
                    },
                    child: Container(
                      decoration: shadowedBoxDecoration.copyWith(
                        border: isSelected
                            ? Border.all(width: 2, color: ROOMY_PURPLE)
                            : Border.all(width: 1, color: Colors.grey),
                      ),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ListTile(
                        leading: Image.asset(e.asset, width: 60),
                        title: Text(
                          e.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (paymentmethodMethod == "STRIPE")
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoading ? null : () => _payRoomyBalance("STRIPE"),
                    icon: const Icon(Icons.credit_card),
                    label: const Text("Pay with Stripe"),
                  ),
                ),
              if (paymentmethodMethod == "PAYPAL") ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoading ? null : () => _payRoomyBalance("PAYPAL"),
                    icon: const Icon(Icons.paypal, color: Colors.blue),
                    label: const Text("Pay with PayPal"),
                  ),
                ),
              ],
            ],
          ),
        ));
  }
}
