import 'package:flutter/material.dart';
import '../../core/utils/haptics.dart';

/// A wrapper around the standard [Slider] widget that adds haptic feedback.
/// Triggering haptics on step changes and drag start/end.
class HapticSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? label;
  final String Function(double)? formatLabel;

  const HapticSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    required this.onChanged,
    this.label,
    this.formatLabel,
  });

  @override
  State<HapticSlider> createState() => _HapticSliderState();
}

class _HapticSliderState extends State<HapticSlider> {
  late double _lastHapticValue;

  @override
  void initState() {
    super.initState();
    _lastHapticValue = widget.value;
  }

  void _handleChanged(double value) {
    if (widget.divisions != null) {
      // For discrete sliders, trigger haptic on each division step
      final step = (widget.max - widget.min) / widget.divisions!;
      final currentStep = ((value - widget.min) / step).round();
      final lastStep = ((_lastHapticValue - widget.min) / step).round();

      if (currentStep != lastStep) {
        HapticsService.selection();
        _lastHapticValue = value;
      }
    } else {
      // For continuous sliders, trigger at 5% intervals
      final range = widget.max - widget.min;
      if (range > 0) {
        if ((value - _lastHapticValue).abs() > range * 0.05) {
          HapticsService.selection();
          _lastHapticValue = value;
        }
      }
    }
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        thumbColor: theme.colorScheme.primary,
        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: theme.colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
      ),
      child: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        onChanged: _handleChanged,
        onChangeStart: (_) => HapticsService.lightTap(),
        onChangeEnd: (_) => HapticsService.success(),
        label: widget.label ?? widget.formatLabel?.call(widget.value),
      ),
    );
  }
}
