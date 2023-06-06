import 'package:flutter/material.dart';
import 'package:roomy_finder/utilities/data.dart';

class MaintenanceButton extends StatelessWidget {
  const MaintenanceButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
  });

  final String label;
  final void Function()? onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 233, 226, 226),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 3),
            blurRadius: 3,
            blurStyle: BlurStyle.normal,
            color: Colors.black38,
            spreadRadius: -1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          side: const BorderSide(color: ROOMY_ORANGE),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
