import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimatedPaw extends StatefulWidget {
  final double top;
  final double left;
  final double size;

  const AnimatedPaw({
    super.key,
    required this.top,
    required this.left,
    this.size = 30,
  });

  @override
  State<AnimatedPaw> createState() => _AnimatedPawState();
}

class _AnimatedPawState extends State<AnimatedPaw>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    animation = Tween(begin: 0.3, end: 0.8).animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      child: FadeTransition(
        opacity: animation,
        child: Icon(
          FontAwesomeIcons.paw,
          size: widget.size,
          color: Colors.teal.withOpacity(0.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
