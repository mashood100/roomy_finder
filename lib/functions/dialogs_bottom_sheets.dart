import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/utilities/data.dart';

Future<bool?> showConfirmDialog(
  String message, {
  String? title,
  bool? isAlert,
  String? refuseText,
  String? confirmText,
  bool? barrierDismissible,
}) async {
  final context = Get.context;
  if (context == null) return null;

  final response = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible ?? true,
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

Future<bool?> showSuccessDialog(
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 40,
              color: Colors.green,
            ),
            const Text(
              "Congratulations!",
              style: TextStyle(
                color: ROOMY_PURPLE,
              ),
            ),
            Text(
              message,
              style: const TextStyle(
                color: ROOMY_PURPLE,
              ),
            ),
          ],
        ),
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

Future<String?> showInlineInputBottomSheet({
  num? initialPrice,
  String label = "",
  String? message,
}) async {
  final context = Get.context;

  String? value;

  if (context == null) return null;

  await showModalBottomSheet(
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
            if (message != null)
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 10),
            InlineTextField(
              labelText: label,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(),
              onChanged: (val) {
                value = val;
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text("cancel".tr),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () {
                    Get.back(result: value);
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
  return value;
}
