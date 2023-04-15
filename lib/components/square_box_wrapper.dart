import 'package:flutter/material.dart';

class SquareBoxWrapper extends StatelessWidget {
  const SquareBoxWrapper({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            blurStyle: BlurStyle.outer,
            color: Colors.black54,
            spreadRadius: -1,
          ),
        ],
      ),
      child: child,
    );
  }
}
