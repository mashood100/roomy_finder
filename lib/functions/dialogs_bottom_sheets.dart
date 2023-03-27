import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/utilities/data.dart';

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
