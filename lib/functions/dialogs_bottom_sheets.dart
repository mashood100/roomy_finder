import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/data/constants.dart';

Future<num?> showPriceInputBottomSheet({
  num? initialPrice,
  String label = "price",
}) async {
  final context = Get.context;

  if (context == null) return null;

  final priceController = TextEditingController(
    text: initialPrice == null ? "" : initialPrice.toString(),
  );
  final shouldCreate = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        top: 10,
        right: 10,
        left: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                  border: UnderlineInputBorder(), suffixText: 'ADB'),
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.allow(priceRegex)],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text("cancel".tr),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    Get.back(result: true);
                  },
                  child: Text("ok".tr),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (shouldCreate != true) return null;
  return num.parse(priceController.text);
}

Future<bool?> showConfirmDialog(
  String message, {
  String? title,
  bool? isAlert,
  String? refuseText,
  String? confirmText,
}) async {
  final context = Get.context;
  if (context == null) return null;

  final response = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: isAlert != true
            ? [
                CupertinoDialogAction(
                  onPressed: () => Get.back(result: false),
                  child: Text(refuseText ?? "no".tr),
                ),
                CupertinoDialogAction(
                  onPressed: () => Get.back(result: true),
                  child: Text(confirmText ?? "yes".tr),
                ),
              ]
            : [
                CupertinoDialogAction(
                  onPressed: () => Get.back(result: true),
                  child: Text(confirmText ?? "ok".tr),
                ),
              ],
      );
    },
  );

  return response == true;
}
