import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label({
    super.key,
    required this.label,
    required this.value,
    this.hr = false,
    this.boldValue = true,
    this.icon,
    this.valueColor,
    this.fontSize,
    this.boldLabel,
  });

  final String label;
  final Object value;
  final bool? hr;
  final bool boldValue;
  final Widget? icon;
  final Color? valueColor;
  final double? fontSize;
  final bool? boldLabel;

  @override
  Widget build(BuildContext context) {
    double labelWidth = MediaQuery.sizeOf(context).width * 0.4;

    final maxLabelWidth = icon != null ? 150.0 : 100.0;

    if (labelWidth > maxLabelWidth) labelWidth = maxLabelWidth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: labelWidth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 10)],
                  Text(label),
                ],
              ),
            ),
            Expanded(
              child: Text(
                "$value",
                style: const TextStyle().merge(
                  TextStyle(
                    fontWeight:
                        boldValue == true ? FontWeight.bold : FontWeight.normal,
                    color: valueColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hr == true) const Divider() else const SizedBox(height: 15)
      ],
    );
  }
}
