import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showFinishedDialog(String message) async {
  if (Get.context == null) return;
  await showDialog(
    context: Get.context!,
    builder: (context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          height: Get.height * 0.7,
          width: Get.width * 0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
              const SizedBox(height: 40),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text("Done"),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    },
  );
}
