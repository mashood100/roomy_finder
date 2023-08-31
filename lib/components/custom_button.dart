import 'package:flutter/material.dart';
import 'package:roomy_finder/utilities/data.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? color;
  final void Function()? onPressed;
  final double? borderRaduis;
  final EdgeInsets? padding;
  final bool boldLabel;

  const CustomButton(
    this.title, {
    super.key,
    this.height,
    this.width,
    this.backgroundColor,
    this.color,
    this.onPressed,
    this.borderRaduis,
    this.padding,
    this.boldLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? ROOMY_ORANGE,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRaduis ?? 5),
          ),
          side: BorderSide(color: backgroundColor ?? ROOMY_ORANGE),
          padding: padding ?? const EdgeInsets.all(12),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: boldLabel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
