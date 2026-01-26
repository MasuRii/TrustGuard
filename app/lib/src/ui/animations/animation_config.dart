import 'package:flutter/material.dart';

class AnimationConfig {
  static const defaultDuration = Duration(milliseconds: 300);
  static const longDuration = Duration(milliseconds: 500);
  static const containerTransformDuration = Duration(milliseconds: 400);
  static const numberCountDuration = Duration(milliseconds: 800);

  static bool useReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
