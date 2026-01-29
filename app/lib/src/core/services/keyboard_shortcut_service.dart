import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/platform_utils.dart';

/// Intent for creating a new expense.
class NewExpenseIntent extends Intent {
  const NewExpenseIntent();
}

/// Intent for creating a new transfer.
class NewTransferIntent extends Intent {
  const NewTransferIntent();
}

/// Intent for saving a form.
class SaveIntent extends Intent {
  const SaveIntent();
}

/// Intent for cancelling/closing.
class CancelIntent extends Intent {
  const CancelIntent();
}

/// Intent for searching.
class SearchIntent extends Intent {
  const SearchIntent();
}

/// Service providing keyboard shortcut configurations.
class KeyboardShortcutService {
  /// Returns a platform-appropriate shortcut activator for the given key.
  ///
  /// Uses Meta (Command) on macOS and Control on other platforms.
  static ShortcutActivator platformShortcut(LogicalKeyboardKey key) {
    return SingleActivator(
      key,
      control: !PlatformUtils.isMacOS,
      meta: PlatformUtils.isMacOS,
    );
  }

  /// Default global shortcuts for the application.
  static Map<ShortcutActivator, Intent> get defaultShortcuts {
    return {
      platformShortcut(LogicalKeyboardKey.keyN): const NewExpenseIntent(),
      platformShortcut(LogicalKeyboardKey.keyT): const NewTransferIntent(),
      platformShortcut(LogicalKeyboardKey.keyS): const SaveIntent(),
      platformShortcut(LogicalKeyboardKey.keyF): const SearchIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const CancelIntent(),
    };
  }
}

/// A widget that wraps its child with global keyboard shortcuts and actions.
class AppShortcuts extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The actions to associate with the intents.
  final Map<Type, Action<Intent>>? actions;

  const AppShortcuts({super.key, required this.child, this.actions});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: KeyboardShortcutService.defaultShortcuts,
      child: Actions(
        actions: actions ?? <Type, Action<Intent>>{},
        child: child,
      ),
    );
  }
}
