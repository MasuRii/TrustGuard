import 'package:flutter/material.dart';
import '../../core/services/undoable_action_service.dart';
import '../../core/utils/haptics.dart';
import '../../generated/app_localizations.dart';

/// Configuration for the undo snackbar.
class UndoSnackBarConfig {
  /// The message to display in the snackbar.
  final String message;

  /// Optional label for the undo action. Defaults to 'Undo' from l10n.
  final String? undoLabel;

  /// How long the snackbar should be visible. Defaults to 5 seconds.
  final Duration duration;

  /// Optional callback to execute when the undo action is triggered.
  final VoidCallback? onUndo;

  const UndoSnackBarConfig({
    required this.message,
    this.undoLabel,
    this.duration = const Duration(seconds: 5),
    this.onUndo,
  });
}

/// Helper function to show a snackbar with an undo action and a progress indicator.
void showUndoSnackBar({
  required BuildContext context,
  required String message,
  required String actionId,
  required UndoableActionService undoService,
  UndoSnackBarConfig? config,
}) {
  final l10n = AppLocalizations.of(context)!;
  final duration = config?.duration ?? const Duration(seconds: 5);

  // Hide any existing snackbar before showing the new one.
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      content: _UndoSnackBarContent(message: message, duration: duration),
      action: SnackBarAction(
        label: config?.undoLabel ?? l10n.undo,
        onPressed: () async {
          final success = await undoService.cancel(actionId);
          if (success) {
            config?.onUndo?.call();
            HapticsService.success();
            if (context.mounted) {
              // Show a brief confirmation that the action was undone.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.actionUndone),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    ),
  );
}

class _UndoSnackBarContent extends StatefulWidget {
  final String message;
  final Duration duration;

  const _UndoSnackBarContent({required this.message, required this.duration});

  @override
  State<_UndoSnackBarContent> createState() => _UndoSnackBarContentState();
}

class _UndoSnackBarContentState extends State<_UndoSnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..reverse(from: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.message),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _controller.value,
              minHeight: 2,
              backgroundColor: theme.colorScheme.inversePrimary.withValues(
                alpha: 0.2,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.inversePrimary,
              ),
            );
          },
        ),
      ],
    );
  }
}
