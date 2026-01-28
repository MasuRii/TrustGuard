import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'numeric_keypad.dart';
import '../../core/utils/money.dart';
import '../../core/utils/haptics.dart';

/// A widget that combines a large amount display with a numeric keypad.
class AmountInputField extends StatefulWidget {
  /// Initial value in minor units (e.g., 1050 for $10.50).
  final int initialValue;

  /// The currency code to display (e.g., 'USD').
  final String currencyCode;

  /// Callback when the amount changes, returning the value in minor units.
  final ValueChanged<int> onChanged;

  /// Whether to show quick increment buttons (+10, +20, etc.).
  final bool showQuickButtons;

  /// Whether to show the keypad. Defaults to true.
  final bool showKeypad;

  const AmountInputField({
    super.key,
    this.initialValue = 0,
    this.currencyCode = 'USD',
    required this.onChanged,
    this.showQuickButtons = true,
    this.showKeypad = true,
  });

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  late String _amountString;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      final double value = MoneyUtils.fromMinorUnits(widget.initialValue);
      // Format without trailing zeros if they are .00
      if (value == value.toInt()) {
        _amountString = value.toInt().toString();
      } else {
        _amountString = value.toString();
      }
    } else {
      _amountString = '';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateAmount(String newString) {
    setState(() {
      _amountString = newString;
    });

    final double val = double.tryParse(_amountString) ?? 0.0;
    widget.onChanged(MoneyUtils.toMinorUnits(val));

    // Scroll to end if the number gets long
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onDigitPressed(String digit) {
    if (_amountString == '0' && digit == '0') return;

    // Limit total length to prevent overflow
    if (_amountString.length >= 12) return;

    if (_amountString.contains('.')) {
      final parts = _amountString.split('.');
      if (parts[1].length >= 2) return;
    }

    if (_amountString == '0') {
      _updateAmount(digit);
    } else {
      _updateAmount(_amountString + digit);
    }
  }

  void _onDecimalPressed() {
    if (!_amountString.contains('.')) {
      if (_amountString.isEmpty) {
        _updateAmount('0.');
      } else {
        _updateAmount('$_amountString.');
      }
    }
  }

  void _onBackspacePressed() {
    if (_amountString.isNotEmpty) {
      _updateAmount(_amountString.substring(0, _amountString.length - 1));
    }
  }

  void _onClearPressed() {
    _updateAmount('');
  }

  void _addAmount(int amountToAdd) {
    HapticsService.lightTap();
    final double currentVal = double.tryParse(_amountString) ?? 0.0;
    final double newVal = currentVal + amountToAdd;
    // Format to max 2 decimal places to avoid floating point issues
    _updateAmount(newVal.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''));
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final cleanText = data!.text!.replaceAll(RegExp(r'[^0-9.]'), '');
      final val = double.tryParse(cleanText);
      if (val != null) {
        HapticsService.lightTap();
        _updateAmount(val.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencySymbol = NumberFormat.simpleCurrency(
      name: widget.currencyCode,
    ).currencySymbol;

    // Format the display string with thousand separators
    String displayString = _amountString;
    if (_amountString.isNotEmpty && _amountString != '0.') {
      final parts = _amountString.split('.');
      final formatter = NumberFormat(
        '#,###',
        Localizations.localeOf(context).languageCode,
      );
      final intPart = int.tryParse(parts[0]) ?? 0;
      displayString = formatter.format(intPart);
      if (parts.length > 1) {
        displayString += '.${parts[1]}';
      } else if (_amountString.endsWith('.')) {
        displayString += '.';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount Display
        GestureDetector(
          onLongPress: _handlePaste,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currencySymbol,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayString.isEmpty ? '0.00' : displayString,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: displayString.isEmpty
                          ? theme.hintColor.withValues(alpha: 0.3)
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (widget.showQuickButtons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [10, 20, 50, 100].map((amount) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text('+$amount'),
                      onPressed: () => _addAmount(amount),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        if (widget.showKeypad)
          NumericKeypad(
            onDigitPressed: _onDigitPressed,
            onDecimalPressed: _onDecimalPressed,
            onBackspacePressed: _onBackspacePressed,
            onClearPressed: _onClearPressed,
          ),
      ],
    );
  }
}
