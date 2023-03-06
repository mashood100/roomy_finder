// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/data/enums.dart';

void showGetSnackbar(
  String message, {
  String? title,
  int seconds = 5,
  bool isDismissible = false,
  Severity severity = Severity.suceess,
  SnackBarAction? action,
}) {
  final Color color;

  switch (severity) {
    case Severity.error:
      color = Colors.red;
      break;
    case Severity.info:
      color = Colors.blue;
      break;
    case Severity.warning:
      color = const Color.fromARGB(255, 230, 214, 77);
      break;
    default:
      color = Colors.green;
      break;
  }
  final context = Get.context;

  if (context == null) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      action: action,
      duration: Duration(seconds: seconds),
      backgroundColor: color,
      // padding: const EdgeInsets.all(5),
    ),
  );

  // Get.snackbar(
  //   title,
  //   message,
  //   duration: Duration(seconds: seconds),
  //   borderRadius: 0,
  //   padding: const EdgeInsets.all(5),
  //   margin: const EdgeInsets.all(0),
  //   backgroundColor: color,
  //   isDismissible: isDismissible,
  // );
}

void showToast(String message, {Severity? severity, int duration = 2}) {
  final Color? color;

  switch (severity) {
    case Severity.error:
      color = Colors.red;
      break;
    case Severity.info:
      color = Colors.white;
      break;
    case Severity.warning:
      color = const Color.fromARGB(255, 230, 214, 77);
      break;
    default:
      color = Colors.white;
      break;
  }
  Fluttertoast.cancel().then(
    (value) => Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.grey,
      timeInSecForIosWeb: duration,
      textColor: color,
    ),
  );
}
