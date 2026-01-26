import 'package:flutter/material.dart';
import 'package:trustguard/src/core/utils/haptics.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeRange;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.shakeRange = 10.0,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -widget.shakeRange),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.shakeRange, end: widget.shakeRange),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.shakeRange, end: -widget.shakeRange),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.shakeRange, end: widget.shakeRange),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.shakeRange, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
    HapticsService.warning();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
