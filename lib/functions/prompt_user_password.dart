import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<String?> promptUserPassword(BuildContext context) async {
  var hidePassword = true;
  final password = await showModalBottomSheet<String?>(
    context: context,
    builder: (context) {
      var passwordString = "";
      return Padding(
        padding: EdgeInsets.only(
          top: 10,
          right: 10,
          left: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "password".tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (context, setState) {
                return TextField(
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => Get.back(result: value),
                  onChanged: (value) => passwordString = value,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: "enterYourPassword".tr,
                    suffixIcon: IconButton(
                      onPressed: () {
                        hidePassword = !hidePassword;
                        setState(() {});
                      },
                      icon: hidePassword
                          ? const Icon(Icons.visibility)
                          : const Icon(Icons.visibility_off),
                    ),
                  ),
                  autofocus: true,
                );
              }),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: null),
                    child: Text("cancel".tr),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Get.back(result: passwordString),
                    child: Text("ok".tr),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
  return password;
}
