import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockAuth;
  late AppLockService appLockService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockLocalAuthentication();
    appLockService = AppLockService(mockStorage, mockAuth);
  });

  group('AppLockService', () {
    test('isPinSet returns false when no hash is stored', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final result = await appLockService.isPinSet();

      expect(result, isFalse);
      verify(() => mockStorage.read(key: 'app_lock_pin_hash')).called(1);
    });

    test('isPinSet returns true when hash is stored', () async {
      when(
        () => mockStorage.read(key: 'app_lock_pin_hash'),
      ).thenAnswer((_) async => 'some_hash');

      final result = await appLockService.isPinSet();

      expect(result, isTrue);
    });

    test('setPin generates salt and stores hash', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await appLockService.setPin('1234');

      verify(
        () => mockStorage.write(
          key: 'app_lock_pin_hash',
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'app_lock_pin_salt',
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('verifyPin returns true for correct PIN after setPin', () async {
      const pin = '1234';
      final storage = <String, String>{};

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        storage[invocation.namedArguments[#key] as String] =
            invocation.namedArguments[#value] as String;
      });
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((
        invocation,
      ) async {
        return storage[invocation.namedArguments[#key] as String];
      });

      await appLockService.setPin(pin);
      final result = await appLockService.verifyPin(pin);
      expect(result, isTrue);

      final resultWrong = await appLockService.verifyPin('wrong');
      expect(resultWrong, isFalse);
    });

    test('removePin deletes hash, salt, and biometric preference', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await appLockService.removePin();

      verify(() => mockStorage.delete(key: 'app_lock_pin_hash')).called(1);
      verify(() => mockStorage.delete(key: 'app_lock_pin_salt')).called(1);
      verify(
        () => mockStorage.delete(key: 'app_lock_biometric_enabled'),
      ).called(1);
    });

    group('Biometrics', () {
      test('isBiometricAvailable returns true if device supported', () async {
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

        final result = await appLockService.isBiometricAvailable();

        expect(result, isTrue);
      });

      test('authenticateWithBiometrics calls auth.authenticate', () async {
        when(
          () => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
          ),
        ).thenAnswer((_) async => true);

        final result = await appLockService.authenticateWithBiometrics();

        expect(result, isTrue);
        verify(
          () => mockAuth.authenticate(
            localizedReason: 'Unlock TrustGuard',
            biometricOnly: true,
          ),
        ).called(1);
      });

      test('isBiometricEnabled returns correct preference', () async {
        when(
          () => mockStorage.read(key: 'app_lock_biometric_enabled'),
        ).thenAnswer((_) async => 'true');

        final result = await appLockService.isBiometricEnabled();

        expect(result, isTrue);
      });

      test('setBiometricEnabled stores preference', () async {
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await appLockService.setBiometricEnabled(true);

        verify(
          () => mockStorage.write(
            key: 'app_lock_biometric_enabled',
            value: 'true',
          ),
        ).called(1);
      });
    });
  });
}
