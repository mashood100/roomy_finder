import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label({
    super.key,
    required this.label,
    required this.value,
    this.boldValue,
    this.boldLabel,
    this.fontSize,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool? boldValue;
  final bool? boldLabel;
  final double? fontSize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight:
                        boldLabel == true ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize,
                  ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight:
                    boldValue == true ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize ?? 14,
                color: valueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
