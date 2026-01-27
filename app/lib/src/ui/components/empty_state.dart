import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String? lottiePath;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    this.icon,
    this.svgPath,
    this.lottiePath,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  }) : assert(
         icon != null || svgPath != null || lottiePath != null,
         'Either icon, svgPath, or lottiePath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final bool animate = !MediaQuery.of(context).disableAnimations;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottiePath != null)
              Lottie.asset(
                lottiePath!,
                height: 160,
                width: 160,
                animate: animate,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  if (svgPath != null) {
                    return SvgPicture.asset(svgPath!, height: 160, width: 160);
                  } else if (icon != null) {
                    return Icon(
                      icon,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    );
                  }
                  return const SizedBox(height: 160, width: 160);
                },
              )
            else if (svgPath != null)
              SvgPicture.asset(
                svgPath!,
                height: 160,
                width: 160,
                placeholderBuilder: (context) => const SizedBox(
                  height: 160,
                  width: 160,
                  child: CircularProgressIndicator(),
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
            const SizedBox(height: AppTheme.space24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppTheme.space24),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
