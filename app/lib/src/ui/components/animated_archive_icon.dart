import 'package:flutter/material.dart';
import '../animations/animation_config.dart';

class AnimatedArchiveIcon extends StatelessWidget {
  final bool isArchived;
  final double size;

  const AnimatedArchiveIcon({
    super.key,
    required this.isArchived,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final useReducedMotion = AnimationConfig.useReducedMotion(context);

    return Semantics(
      label: isArchived ? 'Archived' : 'Active',
      readOnly: true,
      child: AnimatedSwitcher(
        duration: useReducedMotion
            ? Duration.zero
            : AnimationConfig.defaultDuration,
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: RotationTransition(
              turns: animation.drive(
                Tween<double>(
                  begin: 0.5,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOutBack)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: Icon(
          isArchived ? Icons.archive : Icons.archive_outlined,
          key: ValueKey<bool>(isArchived),
          size: size,
        ),
      ),
    );
  }
}
