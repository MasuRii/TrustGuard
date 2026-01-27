import 'package:flutter/material.dart';
import 'package:trustguard/src/ui/animations/animation_config.dart';

enum CoachmarkPosition { top, bottom, left, right, auto }

class CoachmarkOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final String message;
  final CoachmarkPosition position;
  final VoidCallback onDismiss;
  final bool pulseAnimation;

  const CoachmarkOverlay({
    super.key,
    required this.targetKey,
    required this.message,
    this.position = CoachmarkPosition.auto,
    required this.onDismiss,
    this.pulseAnimation = true,
  });

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String message,
    CoachmarkPosition position = CoachmarkPosition.auto,
    required VoidCallback onDismiss,
    bool pulseAnimation = true,
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => CoachmarkOverlay(
        targetKey: targetKey,
        message: message,
        position: position,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss();
        },
        pulseAnimation: pulseAnimation,
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<CoachmarkOverlay> createState() => _CoachmarkOverlayState();
}

class _CoachmarkOverlayState extends State<CoachmarkOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    if (widget.pulseAnimation &&
        !AnimationConfig.useReducedMotion(context) &&
        !isTest) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // If we can't find the target, dismiss or show nothing
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDismiss());
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop with cutout
          GestureDetector(
            onTap: widget.onDismiss,
            child: Semantics(
              label: 'Dismiss coachmark',
              button: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.7),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    Positioned(
                      left: offset.dx - 8,
                      top: offset.dy - 8,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: size.width + 16,
                              height: size.height + 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tooltip
          _buildTooltip(context, offset, size),
        ],
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    Offset targetOffset,
    Size targetSize,
  ) {
    final screenSize = MediaQuery.of(context).size;

    CoachmarkPosition effectivePosition = widget.position;
    if (effectivePosition == CoachmarkPosition.auto) {
      if (targetOffset.dy < screenSize.height / 2) {
        effectivePosition = CoachmarkPosition.bottom;
      } else {
        effectivePosition = CoachmarkPosition.top;
      }
    }

    double? left, right, top, bottom;

    switch (effectivePosition) {
      case CoachmarkPosition.top:
        bottom = screenSize.height - targetOffset.dy + 16;
        left =
            (targetOffset.dx + targetSize.width / 2) - 100; // Assume 200 width
        break;
      case CoachmarkPosition.bottom:
        top = targetOffset.dy + targetSize.height + 16;
        left = (targetOffset.dx + targetSize.width / 2) - 100;
        break;
      case CoachmarkPosition.left:
        right = screenSize.width - targetOffset.dx + 16;
        top =
            (targetOffset.dy + targetSize.height / 2) - 50; // Assume 100 height
        break;
      case CoachmarkPosition.right:
        left = targetOffset.dx + targetSize.width + 16;
        top = (targetOffset.dy + targetSize.height / 2) - 50;
        break;
      case CoachmarkPosition.auto:
        // Already handled
        top = 0;
        left = 0;
        break;
    }

    // Adjust left/right to keep on screen
    if (left != null) {
      if (left < 16) left = 16;
      if (left + 200 > screenSize.width - 16) left = screenSize.width - 216;
    }
    if (right != null) {
      if (right < 16) right = 16;
      if (right + 200 > screenSize.width - 16) right = screenSize.width - 216;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onDismiss,
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
