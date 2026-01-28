import 'package:flutter/material.dart';
import '../animations/animation_config.dart';

class AnimatedFilterBadge extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const AnimatedFilterBadge({
    super.key,
    required this.isActive,
    required this.child,
  });

  @override
  State<AnimatedFilterBadge> createState() => _AnimatedFilterBadgeState();
}

class _AnimatedFilterBadgeState extends State<AnimatedFilterBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConfig.defaultDuration,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const ElasticOutCurve(0.8),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedFilterBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (AnimationConfig.useReducedMotion(context)) {
        _controller.value = widget.isActive ? 1.0 : 0.0;
      } else {
        if (widget.isActive) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isActive ? 'Filter active' : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            top: -2,
            right: -2,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
