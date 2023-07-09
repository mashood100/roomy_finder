import 'package:flutter/material.dart';

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey.withOpacity(0.3),
      child: CircularProgressIndicator(
        color: Colors.grey.withOpacity(0.8),
        strokeWidth: 2,
      ),
    );
  }
}
