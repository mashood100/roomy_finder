import 'package:flutter/material.dart';
import 'package:get/get.dart';

AppBar createNamedAppBar({
  String? title,
  String? subTitle,
  bool centerTitle = true,
  bool? isLoading,
  bool automaticallyImplyLeading = false,
  bool withDivider = false,
  Color titleColor = Colors.black,
  TextStyle? titleStyle,
}) {
  return AppBar(
    title: Text(
      title ?? 'Roomy Finder'.tr,
      style: titleStyle ??
          TextStyle(
            fontSize: 24,
            color: titleColor,
          ),
    ),
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    bottom: PreferredSize(
      preferredSize: const Size(double.infinity, 30),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            if (withDivider) const Divider(),
            if (isLoading == true) const LinearProgressIndicator(),
            if (subTitle != null)
              Container(
                color: Get.isDarkMode
                    ? Get.theme.appBarTheme.backgroundColor
                    : Get.theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(subTitle),
              ),
          ],
        ),
      ),
    ),
  );
}
