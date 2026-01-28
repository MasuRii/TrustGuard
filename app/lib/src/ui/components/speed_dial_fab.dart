import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/haptics.dart';
import '../animations/animation_config.dart';

class SpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}

class SpeedDialFab extends StatefulWidget {
  final IconData mainIcon;
  final String? mainLabel;
  final List<SpeedDialItem> items;
  final VoidCallback? onMainPressed;

  const SpeedDialFab({
    super.key,
    this.mainIcon = Icons.add,
    this.mainLabel,
    required this.items,
    this.onMainPressed,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.defaultDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hideOverlay(immediate: true);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.items.isEmpty) {
      widget.onMainPressed?.call();
      return;
    }

    if (_isExpanded) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_isExpanded) return;

    setState(() => _isExpanded = true);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
    HapticsService.lightTap();
  }

  void _hideOverlay({bool immediate = false}) {
    if (!_isExpanded) return;

    if (immediate) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isExpanded = false;
      return;
    }

    _controller.reverse().then((_) {
      if (mounted && _isExpanded) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() => _isExpanded = false);
      }
    });
    HapticsService.lightTap();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final useReducedMotion = AnimationConfig.useReducedMotion(context);
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Backdrop
              _buildBackdrop(),
              // Items and Main Button
              Positioned(
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  followerAnchor: Alignment.bottomRight,
                  targetAnchor: Alignment.bottomRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildSpeedDialItems(useReducedMotion),
                      _buildMainFab(inOverlay: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackdrop() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5 * _controller.value),
          ),
        );
      },
    );
  }

  Widget _buildMainFab({bool inOverlay = false}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double rotation = _controller.value * math.pi / 4;

        Widget fab;
        if (_isExpanded || inOverlay) {
          fab = FloatingActionButton(
            onPressed: _toggle,
            heroTag: inOverlay ? 'speed_dial_main_overlay' : 'speed_dial_main',
            child: Transform.rotate(
              angle: rotation,
              child: Icon(widget.mainIcon),
            ),
          );
        } else if (widget.mainLabel != null) {
          fab = FloatingActionButton.extended(
            onPressed: _toggle,
            heroTag: 'speed_dial_main',
            label: Text(widget.mainLabel!),
            icon: Icon(widget.mainIcon),
          );
        } else {
          fab = FloatingActionButton(
            onPressed: _toggle,
            heroTag: 'speed_dial_main',
            child: Icon(widget.mainIcon),
          );
        }

        return Semantics(
          label: _isExpanded
              ? 'Close speed dial'
              : (widget.mainLabel ?? 'Open speed dial'),
          button: true,
          child: fab,
        );
      },
    );
  }

  Widget _buildSpeedDialItems(bool useReducedMotion) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.items.length, (index) {
        // Reverse the list so the first item in the list is the top one
        final item = widget.items[index];
        return _buildItem(item, index, useReducedMotion);
      }),
    );
  }

  Widget _buildItem(SpeedDialItem item, int index, bool useReducedMotion) {
    // Calculate stagger. The items should animate from bottom to top.
    // The last item in the list (index = length - 1) is closest to the FAB.
    // But we are rendering them in a Column [Item0, Item1, ..., FAB].
    // So Item0 is at the top.
    // Animation should stagger such that the one closest to FAB starts first?
    // Usually speed dial items pop out from the FAB.
    // So the item at index (length - 1) should start first.

    final int reverseIndex = widget.items.length - 1 - index;
    final double staggerStart = reverseIndex * 0.1;

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        staggerStart.clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    final itemWidget = Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          FadeTransition(
            opacity: useReducedMotion
                ? const AlwaysStoppedAnimation(1.0)
                : animation,
            child: ScaleTransition(
              scale: useReducedMotion
                  ? const AlwaysStoppedAnimation(1.0)
                  : animation,
              child: GestureDetector(
                onTap: () {
                  _toggle();
                  item.onPressed();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Mini FAB
          ScaleTransition(
            scale: useReducedMotion
                ? const AlwaysStoppedAnimation(1.0)
                : animation,
            child: Semantics(
              label: item.label,
              button: true,
              enabled: true,
              child: FloatingActionButton.small(
                heroTag: 'speed_dial_item_$index',
                onPressed: () {
                  _toggle();
                  item.onPressed();
                },
                backgroundColor:
                    item.backgroundColor ??
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    item.foregroundColor ??
                    Theme.of(context).colorScheme.onSecondaryContainer,
                tooltip: item.label,
                child: Icon(item.icon),
              ),
            ),
          ),
        ],
      ),
    );

    return itemWidget;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Visibility(
        visible: !_isExpanded,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: _buildMainFab(),
      ),
    );
  }
}
