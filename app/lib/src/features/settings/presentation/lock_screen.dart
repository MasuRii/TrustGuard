import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/animations/shake_widget.dart';
import '../../../core/utils/haptics.dart';
import '../providers/lock_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  String _enteredPin = '';
  static const _maxPinLength = 4;
  bool _isVerifying = false;
  bool _hasPromptedBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lockState = ref.read(appLockStateProvider);
      if (lockState.isBiometricEnabled && !_hasPromptedBiometrics) {
        setState(() => _hasPromptedBiometrics = true);
        await _authenticateBiometrically();
      }
    });
  }

  Future<void> _authenticateBiometrically() async {
    final success = await ref
        .read(appLockStateProvider.notifier)
        .authenticateBiometrically();

    if (mounted && !success) {
      // Don't show error if cancelled, but maybe just reset prompt flag?
    }
  }

  void _onDigitPressed(int digit) {
    if (_enteredPin.length < _maxPinLength && !_isVerifying) {
      HapticsService.lightTap();
      setState(() {
        _enteredPin += digit.toString();
      });

      if (_enteredPin.length == _maxPinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty && !_isVerifying) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final lockState = ref.read(appLockStateProvider);
    if (lockState.isBlocked) {
      _showBlockedMessage(lockState.blockUntil!);
      setState(() {
        _enteredPin = '';
      });
      return;
    }

    setState(() => _isVerifying = true);

    // Artificial delay for better UX feel
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final success = await ref
        .read(appLockStateProvider.notifier)
        .unlock(_enteredPin);

    if (mounted) {
      if (!success) {
        _shakeKey.currentState?.shake();
        final newLockState = ref.read(appLockStateProvider);
        setState(() {
          _enteredPin = '';
          _isVerifying = false;
        });

        if (newLockState.isBlocked) {
          _showBlockedMessage(newLockState.blockUntil!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incorrect PIN (${5 - newLockState.failedAttempts} attempts left)',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        HapticsService.success();
        // Success handled by router/state change
      }
    }
  }

  void _showBlockedMessage(DateTime until) {
    final remaining = until.difference(DateTime.now()).inSeconds;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Too many attempts. Try again in $remaining seconds.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockState = ref.watch(appLockStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              lockState.isBlocked ? Icons.error_outline : Icons.lock_outline,
              size: 64,
              color: lockState.isBlocked
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              lockState.isBlocked ? 'Blocked' : 'Enter PIN',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ShakeWidget(
              key: _shakeKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_maxPinLength, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 1),
            _buildNumericPad(theme),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericPad(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitButton(1),
              _buildDigitButton(2),
              _buildDigitButton(3),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitButton(4),
              _buildDigitButton(5),
              _buildDigitButton(6),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitButton(7),
              _buildDigitButton(8),
              _buildDigitButton(9),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBiometricButton(theme),
              _buildDigitButton(0),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton(ThemeData theme) {
    final lockState = ref.watch(appLockStateProvider);
    if (!lockState.isBiometricEnabled) {
      return const SizedBox(width: 64, height: 64);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _authenticateBiometrically,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Icon(
            Icons.fingerprint,
            size: 32,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDigitButton(int digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Text(
            digit.toString(),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: const Icon(Icons.backspace_outlined),
        ),
      ),
    );
  }
}
