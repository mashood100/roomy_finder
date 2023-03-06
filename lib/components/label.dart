import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
