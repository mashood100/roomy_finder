import 'package:flutter/material.dart';
import 'package:roomy_finder/utilities/data.dart';

class CustomBottomNavbarIcon extends StatelessWidget {
  final bool isCurrent;
  final Widget icon;
  const CustomBottomNavbarIcon({
    super.key,
    required this.icon,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isCurrent ? ROOMY_PURPLE : null,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        icon,
      ],
    );
  }
}