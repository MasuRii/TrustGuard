import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../app/providers.dart';

part 'lock_providers.freezed.dart';

@freezed
class AppLockState with _$AppLockState {
  const factory AppLockState({
    required bool isLocked,
    @Default(0) int failedAttempts,
    @Default(false) bool isBiometricEnabled,
    @Default(true) bool lockOnBackground,
    @Default(false) bool isInitialized,
    @Default(false) bool hasPin,
    DateTime? blockUntil,
  }) = _AppLockState;

  const AppLockState._();

  bool get isBlocked =>
      blockUntil != null && blockUntil!.isAfter(DateTime.now());
}

class AppLockNotifier extends Notifier<AppLockState> {
  @override
  AppLockState build() {
    return const AppLockState(isLocked: false);
  }

  Future<void> init() async {
    final service = ref.read(appLockServiceProvider);
    final hasPin = await service.isPinSet();
    state = state.copyWith(
      isLocked: hasPin,
      hasPin: hasPin,
      isInitialized: true,
    );
  }

  Future<bool> unlock(String pin) async {
    if (state.isBlocked) return false;

    final service = ref.read(appLockServiceProvider);
    final success = await service.verifyPin(pin);

    if (success) {
      state = state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        blockUntil: null,
      );
      return true;
    } else {
      final newAttempts = state.failedAttempts + 1;
      DateTime? blockUntil;
      if (newAttempts >= 5) {
        blockUntil = DateTime.now().add(const Duration(minutes: 1));
      }
      state = state.copyWith(
        failedAttempts: newAttempts,
        blockUntil: blockUntil,
      );
      return false;
    }
  }

  void lock() {
    if (state.hasPin) {
      state = state.copyWith(isLocked: true);
    }
  }

  void setLockOnBackground(bool value) {
    state = state.copyWith(lockOnBackground: value);
  }
}

final appLockStateProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  () {
    return AppLockNotifier();
  },
);
