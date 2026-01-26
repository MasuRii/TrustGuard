import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing app-level PIN lock.
///
/// Uses [FlutterSecureStorage] to store the hashed PIN and salt securely.
class AppLockService {
  final FlutterSecureStorage _storage;
  static const _pinHashKey = 'app_lock_pin_hash';
  static const _pinSaltKey = 'app_lock_pin_salt';

  AppLockService(this._storage);

  /// Checks if a PIN has been set.
  Future<bool> isPinSet() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Sets or updates the app lock PIN.
  ///
  /// The PIN is hashed with a new random salt before storage.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
  }

  /// Verifies the provided [pin] against the stored hash.
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final storedSalt = await _storage.read(key: _pinSaltKey);

    if (storedHash == null || storedSalt == null) return false;

    final hash = _hashPin(pin, storedSalt);
    return hash == storedHash;
  }

  /// Removes the app lock PIN, effectively disabling it.
  Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(values);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
