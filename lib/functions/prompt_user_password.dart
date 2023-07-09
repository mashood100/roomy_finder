import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/inputs.dart';

Future<String?> promptUserPassword(BuildContext context) async {
  var hidePassword = true;
  var passwordString = "";
  final password = await showModalBottomSheet<String?>(
    context: context,
    builder: (context) {
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
                return InlineTextField(
                  textInputAction: TextInputAction.done,
                  hintText: "Enter your password",
                  obscureText: hidePassword,
                  onChanged: (value) => passwordString = value,
                  autofocus: true,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                    icon: hidePassword
                        ? const Icon(CupertinoIcons.eye)
                        : const Icon(CupertinoIcons.eye_slash),
                  ),
                  onSubmit: (val) => Get.back(result: val),
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
