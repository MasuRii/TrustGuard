import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'animation_config.dart';

enum TransitionType {
  fadeThrough,
  sharedAxisHorizontal,
  sharedAxisVertical,
  none,
}

class AppPageTransitions {
  static Page<T> buildPage<T>({
    required BuildContext context,
    required Widget child,
    required TransitionType type,
    LocalKey? key,
  }) {
    if (AnimationConfig.useReducedMotion(context) ||
        type == TransitionType.none) {
      return MaterialPage<T>(key: key, child: child);
    }

    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case TransitionType.fadeThrough:
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              fillColor: Colors.transparent,
              child: child,
            );
          case TransitionType.sharedAxisHorizontal:
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Colors.transparent,
              child: child,
            );
          case TransitionType.sharedAxisVertical:
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.vertical,
              fillColor: Colors.transparent,
              child: child,
            );
          case TransitionType.none:
            return child;
        }
      },
      transitionDuration: AnimationConfig.defaultDuration,
    );
  }
}
