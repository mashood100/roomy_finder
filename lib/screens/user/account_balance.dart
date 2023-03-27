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
import 'package:url_launcher/url_launcher.dart';

class AccountBalanceScreen extends StatefulWidget {
  const AccountBalanceScreen({super.key});

  @override
  State<AccountBalanceScreen> createState() => _AccountBalanceScreenState();
}

class _AccountBalanceScreenState extends State<AccountBalanceScreen> {
  var _amountToWithDraw = AppController.instance.accountBalance;
  var _isLoading = false;
  String? stripeConnectId;

  @override
  void initState() {
    fetchAccountDetails();
    super.initState();
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
    try {
      _isLoading = (true);
      switch (service) {
        case "STRIPE":
        case "PAYPAL":
          final String endPoint;

          if (service == "STRIPE") {
            endPoint = "/transactions/payouts/stripe/withdraw";
          } else if (service == "PAYPAL") {
            endPoint = "/transactions/payouts/paypal/withdraw";
          } else {
            return;
          }
          try {
            _isLoading = (true);

            // 1. create payment intent on the server
            final res = await ApiService.getDio.post(
              endPoint,
              data: {"amount": amount},
            );

            if (res.statusCode == 200) {
              showToast(
                "Transaction initiated. You will recieve"
                " notification after processing.",
              );
              _isLoading = (false);
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

      // 1. create payment intent on the server
      final res = await ApiService.getDio.post(
        "/transactions/payouts/stripe/connected-account",
      );

      if (res.statusCode == 200) {
        showToast("Payment initiated. Redirecting....");
        _isLoading = (false);

        final uri = Uri.parse(res.data["paymentUrl"]);
        Get.back();

        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
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
        title: const Text("Account balance"),
      ),
      body: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                formatMoney(AppController.instance.accountBalance),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          InlineTextField(
            labelText: "Withdraw amount",
            initialValue: _amountToWithDraw.toString(),
            enabled: !_isLoading,
            onChanged: (value) {
              _amountToWithDraw = num.parse(value);
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(priceRegex)],
          ),
          const SizedBox(height: 20),
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
                onPressed: () {
                  _withdrawMoney("STRIPE");
                },
                icon: const Icon(Icons.credit_card),
                label: const Text("Withdraw with Stripe"),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _withdrawMoney("PAYPAL");
              },
              icon: const Icon(Icons.paypal, color: Colors.blue),
              label: const Text("Withdraw with PayPal"),
            ),
          ),
        ],
      ),
    );
  }
}
