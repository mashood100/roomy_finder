import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  var _amountToWithDraw = AppController.instance.accountBalance;
  var _isLoading = false;
  String? stripeConnectId;
  String? withdrawMethod;

  final _paypalEmailController = TextEditingController(
    text: AppController.me.email,
  );

  @override
  void initState() {
    fetchAccountDetails();
    super.initState();
  }

  @override
  void dispose() {
    _paypalEmailController.dispose();
    super.dispose();
  }

  Future<void> fetchAccountDetails() async {
    setState(() => _isLoading = true);
    final data = await AppController.instance.getAccountInfo();
    if (data != null) {
      stripeConnectId = data["stripeConnectId"];
    }

    setState(() => _isLoading = false);
  }

  Future<void> _withdrawMoney(String service) async {
    final amount = _amountToWithDraw * AppController.convertionRate;
    if (amount < 1000) {
      showToast(
        "Amount too small. Minimum is"
        " ${1000 * AppController.convertionRate} "
        "${AppController.instance.country.value.currencyCode}",
      );
      return;
    }
    final shouldContinue = await showConfirmDialog("Please confirm");
    if (shouldContinue != true) return;
    try {
      _isLoading = (true);
      switch (service) {
        case "PAYPAL":
          if (!_paypalEmailController.text.isEmail) {
            showToast("Invalid email");
            return;
          }
          final String endPoint;

          if (service == "STRIPE") {
            endPoint = "/transactions/payout/stripe/withdraw";
          } else if (service == "PAYPAL") {
            endPoint = "/transactions/payout/paypal/withdraw";
          } else {
            return;
          }
          try {
            _isLoading = (true);

            final res = await ApiService.getDio.post(
              endPoint,
              data: {"amount": amount, "email": _paypalEmailController.text},
            );

            if (res.statusCode == 200) {
              showToast(
                "Transaction initiated. You will recieve"
                " notification after processing.",
              );
            } else if (res.statusCode == 403) {
              showToast("Insufficient balance");
            } else {
              showConfirmDialog("Failed to initiate transaction",
                  isAlert: true);
              Get.log("${res.data}}");
              return;
            }
          } catch (e, trace) {
            showGetSnackbar("Something went wrong", severity: Severity.error);
            Get.log('$trace');
          } finally {
            _isLoading = (false);
          }

          break;

        default:
      }
    } catch (e, trace) {
      showGetSnackbar("Something went wrong", severity: Severity.error);
      Get.log('$trace');
    } finally {
      _isLoading = (false);
    }
  }

  Future<void> _connectStripeAccount() async {
    try {
      _isLoading = (true);

      final res = await ApiService.getDio.post(
        "/transactions/payout/stripe/connected-account",
      );

      if (res.statusCode == 200) {
        showToast("Payment initiated. Redirecting....");
        _isLoading = (false);

        final uri = Uri.parse(res.data["paymentUrl"]);
        Get.back();

        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (res.statusCode == 503) {
        showToast(
          res.data["message"] ?? "Gateway error. Please try again",
        );
        _isLoading = (false);
      } else {
        showConfirmDialog("Failed to connect stripe account", isAlert: true);
        Get.log("${res.data}}");
        return;
      }
    } catch (e, trace) {
      showGetSnackbar("Something went wrong", severity: Severity.error);
      Get.log('$trace');
    } finally {
      _isLoading = (false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Withdraw"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Text(
                  formatMoney(AppController.instance.accountBalance),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            InlineTextField(
              labelWidth: Get.width * 0.3,
              labelText: "Withdraw now",
              hintText: " Amount to withdraw",
              suffixText: AppController.instance.country.value.currencyCode,
              initialValue: _amountToWithDraw.toString(),
              enabled: !_isLoading,
              onChanged: (value) {
                if (value.isEmpty) {
                  _amountToWithDraw = 0;
                } else {
                  _amountToWithDraw = num.parse(value);
                }
              },
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(priceRegex)],
            ),
            const Divider(height: 40),
            // Withdraw method
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => withdrawMethod = "STRIPE"),
                  child: Icon(
                    withdrawMethod == "STRIPE"
                        ? Icons.check_circle_outline_outlined
                        : Icons.circle_outlined,
                    color: ROOMY_ORANGE,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => withdrawMethod = "STRIPE"),
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
                  onTap: () => setState(() => withdrawMethod = "PAYPAL"),
                  child: Icon(
                    withdrawMethod == "PAYPAL"
                        ? Icons.check_circle_outline_outlined
                        : Icons.circle_outlined,
                    color: ROOMY_ORANGE,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => withdrawMethod = "PAYPAL"),
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

            if (withdrawMethod == "STRIPE")
              if (stripeConnectId == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _connectStripeAccount();
                    },
                    icon: const Icon(Icons.credit_card),
                    label: const Text("Connect Stipe Account"),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _withdrawMoney("STRIPE");
                          },
                    icon: const Icon(Icons.credit_card),
                    label: const Text("Withdraw with Stripe"),
                  ),
                ),
            if (withdrawMethod == "PAYPAL") ...[
              InlineTextField(
                labelWidth: Get.width * 0.3,
                labelText: "Paypal email",
                controller: _paypalEmailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _withdrawMoney("PAYPAL");
                        },
                  icon: const Icon(Icons.paypal, color: Colors.blue),
                  label: const Text("Withdraw with PayPal"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
