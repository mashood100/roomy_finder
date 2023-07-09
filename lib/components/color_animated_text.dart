import 'package:flutter/material.dart';

class OpacityAnimatedText extends StatefulWidget {
  const OpacityAnimatedText({
    super.key,
    required this.child,
    this.seconds = 2,
  });
  final int seconds;

  final Widget child;

  @override
  State<OpacityAnimatedText> createState() => OpacityAnimatedTextState();
}

class OpacityAnimatedTextState extends State<OpacityAnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacityAnimation;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
      reverseDuration: Duration(seconds: widget.seconds),
    )
      ..forward()
      ..addListener(() {
        if (controller.isCompleted) {
          controller.repeat(
            period: Duration(seconds: widget.seconds),
            reverse: true,
          );
        }
        setState(() {});
      });
    opacityAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(controller);

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacityAnimation.value,
      child: widget.child,
    );
  }
}
