import 'package:flutter/material.dart';
import 'package:roomy_finder/data/enums.dart';

class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.text,
    this.severity = Severity.info,
    this.trailing,
  });
  final String text;
  final Severity severity;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Icon icon;
    final Color borderColor;
    switch (severity) {
      case Severity.suceess:
        borderColor = Colors.green;
        icon = const Icon(Icons.beenhere_rounded, color: Colors.green);
        break;
      case Severity.error:
        borderColor = Colors.red;
        icon = const Icon(Icons.error, color: Colors.red);
        break;
      case Severity.warning:
        borderColor = const Color.fromARGB(255, 216, 195, 6);
        icon = const Icon(
          Icons.warning,
          color: Color.fromARGB(255, 216, 195, 6),
        );
        break;
      case Severity.info:
        borderColor = Colors.blue;
        icon = const Icon(Icons.info, color: Colors.blue);
        break;
    }
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 1, top: 1, bottom: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: borderColor,
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
            if (trailing != null) trailing!
          ],
        ),
      ),
    );
  }
}
