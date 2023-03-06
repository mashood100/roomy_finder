import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';

class _DepositController extends LoadingController {
  final _cardFormKey = GlobalKey<FormState>();

  late final PageController _pageController;
  final _pageIndex = 0.obs;

  @override
  void onInit() {
    _pageController = PageController();
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    super.onClose();
  }

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

class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_DepositController());
    return Scaffold(
      appBar: AppBar(title: const Text("Upgrade plan")),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: PageView(
            controller: controller._pageController,
            onPageChanged: (index) => controller._pageIndex(index),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              SingleChildScrollView(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Payment details",
                          style: TextStyle(fontSize: 18),
                        ),
                        const Label(label: "Ad fee", value: '200 AED'),
                        const Label(label: "VAT", value: '5%'),
                        const Label(label: "Admin fee", value: '3%'),
                        const Label(label: "Total", value: 'AED xxx'),
                        CreditCardForm(
                          formKey: controller._cardFormKey,
                          cardNumber: controller.cardDetails["cardNumber"]!,
                          expiryDate: controller.cardDetails["expiryDate"]!,
                          cardHolderName:
                              controller.cardDetails["cardHolderName"]!,
                          cvvCode: controller.cardDetails["cvvCode"]!,
                          onCreditCardModelChange: (card) {
                            controller.cardDetails["cardNumber"] =
                                card.cardNumber;
                            controller.cardDetails["cvvCode"] = card.cvvCode;
                            controller.cardDetails["expiryDate"] =
                                card.expiryDate;
                            controller.cardDetails["cardHolderName"] =
                                card.cardHolderName;
                          },
                          themeColor: Colors.purple,
                          textColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        const SizedBox(height: 10),
                        Row(
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
                                child: const Text("Make Payment"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.back(result: true);
                                },
                                child: const Text("Skip"),
                              ),
                            ),
                          ],
                        ),
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
              ),
            ],
          ),
        );
      }),
    );
  }
}
