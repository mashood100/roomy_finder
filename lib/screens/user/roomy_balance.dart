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
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomyBalanceScreen extends StatefulWidget {
  const RoomyBalanceScreen({super.key});

  @override
  State<RoomyBalanceScreen> createState() => _RoomyBalanceScreenState();
}

class _RoomyBalanceScreenState extends State<RoomyBalanceScreen> {
  num _amountToWithDraw = 0;
  var _isLoading = false;
  String? stripeConnectId;
  String? paymentmethodMethod;
  num? roomyBalance;

  final _paypalEmailController = TextEditingController(
    text: AppController.me.email,
  );

  @override
  void initState() {
    fetchAccountDetails();

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;
      // AppController.instance.haveNewMessage(false);
      switch (data["event"]) {
        case "roomy-balance-payment-successfully":
          fetchAccountDetails();

          break;
        default:
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _paypalEmailController.dispose();
    super.dispose();
  }

  Future<void> fetchAccountDetails() async {
    try {
      setState(() => _isLoading = true);
      final res = await ApiService.getDio.get("/profile/account-details");

      if (res.statusCode == 200) {
        roomyBalance = res.data['roomyBalance'];
        final data = res.data;
        stripeConnectId = data["stripeConnectId"];
        roomyBalance = data["roomyBalance"];
      }
    } catch (e) {
      showToast("Failed to load balance");
      log(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _payRoomyBalance(String service) async {
    final amount = _amountToWithDraw * AppController.convertionRate;
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
      appBar: AppBar(title: const Text("Roomy Balance")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Text(
                      roomyBalance != null ? formatMoney(roomyBalance!) : "???",
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Pay now",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  InlineTextField(
                    labelWidth: 0,
                    hintText: "Amount to  pay",
                    suffixText:
                        AppController.instance.country.value.currencyCode,
                    enabled: !_isLoading,
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _amountToWithDraw = 0;
                      } else {
                        _amountToWithDraw = num.parse(value);
                      }
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
                    ],
                  ),
                  const Divider(height: 40),
                  // Withdraw method
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => paymentmethodMethod = "STRIPE"),
                        child: Icon(
                          paymentmethodMethod == "STRIPE"
                              ? Icons.check_circle_outline_outlined
                              : Icons.circle_outlined,
                          color: ROOMY_ORANGE,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => paymentmethodMethod = "STRIPE"),
                        child: const Text(
                          "Stripe",
                          style: TextStyle(
                            color: ROOMY_PURPLE,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => paymentmethodMethod = "PAYPAL"),
                        child: Icon(
                          paymentmethodMethod == "PAYPAL"
                              ? Icons.check_circle_outline_outlined
                              : Icons.circle_outlined,
                          color: ROOMY_ORANGE,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => paymentmethodMethod = "PAYPAL"),
                        child: const Text(
                          "Paypal",
                          style: TextStyle(
                            color: ROOMY_PURPLE,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (paymentmethodMethod == "STRIPE")
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _payRoomyBalance("STRIPE"),
                        icon: const Icon(Icons.credit_card),
                        label: const Text("Pay with Stripe"),
                      ),
                    ),
                  if (paymentmethodMethod == "PAYPAL") ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _payRoomyBalance("PAYPAL"),
                        icon: const Icon(Icons.paypal, color: Colors.blue),
                        label: const Text("Pay with PayPal"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
