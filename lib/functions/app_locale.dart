import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/app_locale.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

Future<void> changeAppLocale(BuildContext context) async {
  final appLocale = await showModalBottomSheet<AppLocale?>(
    context: context,
    builder: (context) {
      return CupertinoScrollbar(
        child: ListView.builder(
          itemBuilder: (context, index) {
            final appLocale = AppLocale.supportedLocales[index];
            return ListTile(
              onTap: () => Get.back(result: appLocale),
              title: Text(appLocale.languageName),
              trailing: AppController.locale == appLocale
                  ? const Icon(
                      Icons.check_circle_sharp,
                      color: Colors.green,
                    )
                  : null,
            );
          },
          itemCount: AppLocale.supportedLocales.length,
        ),
      );
    },
  );

  if (appLocale != null && appLocale != AppController.locale) {
    AppController.instance.setAppLocale(appLocale);
  }
}
