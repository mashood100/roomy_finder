import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';

class _UpgradePlanController extends LoadingController {
  final _cardFormKey = GlobalKey<FormState>();

  final cardDetails = {
    "cardNumber": "",
    "expiryDate": "",
    "cardHolderName": "",
    "cvvCode": "",
  }.obs;

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
        return SingleChildScrollView(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  CreditCardWidget(
                    // formKey: controller._cardFormKey,
                    cardNumber: controller.cardDetails["cardNumber"]!,
                    expiryDate: controller.cardDetails["expiryDate"]!,
                    cardHolderName: controller.cardDetails["cardHolderName"]!,
                    cvvCode: controller.cardDetails["cvvCode"]!,
                    onCreditCardWidgetChange: (card) {},
                    showBackView: false,
                    obscureCardNumber: false,
                    obscureCardCvv: false,
                  ),
                  CreditCardForm(
                    formKey: controller._cardFormKey,
                    cardNumber: controller.cardDetails["cardNumber"]!,
                    expiryDate: controller.cardDetails["expiryDate"]!,
                    cardHolderName: controller.cardDetails["cardHolderName"]!,
                    cvvCode: controller.cardDetails["cvvCode"]!,
                    onCreditCardModelChange: (card) {
                      controller.cardDetails["cardNumber"] = card.cardNumber;
                      controller.cardDetails["cvvCode"] = card.cvvCode;
                      controller.cardDetails["expiryDate"] = card.expiryDate;
                      controller.cardDetails["cardHolderName"] =
                          card.cardHolderName;
                    },
                    themeColor: Colors.purple,
                    textColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (controller._cardFormKey.currentState
                                      ?.validate() ==
                                  true) {
                                controller.upgradePlan();
                              }
                            },
                            child: const Text("Upgrade"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              skipCallback!();
                            },
                            child: const Text("Skip"),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
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
          ),
        );
      }),
    );
  }
}
