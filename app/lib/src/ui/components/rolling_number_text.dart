import 'package:flutter/material.dart';
import '../animations/animation_config.dart';

/// A text widget that animates numeric value changes.
///
/// It uses [ImplicitlyAnimatedWidget] to smoothly transition between values.
/// Respects system-wide reduced motion preferences.
class RollingNumberText extends ImplicitlyAnimatedWidget {
  /// The numeric value to display.
  final int value;

  /// The text style to apply.
  final TextStyle? style;

  /// Optional function to format the integer value as a string.
  /// If null, [value.toString()] is used.
  final String Function(int)? formatFn;

  const RollingNumberText({
    super.key,
    required this.value,
    this.style,
    this.formatFn,
    super.duration = AnimationConfig.numberCountDuration,
    super.curve = Curves.easeOutCubic,
    super.onEnd,
  });

  @override
  ImplicitlyAnimatedWidgetState<RollingNumberText> createState() =>
      _RollingNumberTextState();
}

class _RollingNumberTextState
    extends AnimatedWidgetBaseState<RollingNumberText> {
  IntTween? _value;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _value =
        visitor(
              _value,
              widget.value,
              (dynamic value) => IntTween(begin: value as int),
            )
            as IntTween?;
  }

  @override
  Widget build(BuildContext context) {
    final int value;
    if (AnimationConfig.useReducedMotion(context)) {
      value = widget.value;
    } else {
      value = _value?.evaluate(animation) ?? widget.value;
    }

    final text = widget.formatFn?.call(value) ?? value.toString();

    return Text(
      text,
      style: widget.style,
      textAlign:
          TextAlign.end, // Default for numbers, can be overridden if needed
    );
  }
}
