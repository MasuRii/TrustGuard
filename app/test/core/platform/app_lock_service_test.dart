import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late AppLockService appLockService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    appLockService = AppLockService(mockStorage);
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

    test('removePin deletes hash and salt', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await appLockService.removePin();

      verify(() => mockStorage.delete(key: 'app_lock_pin_hash')).called(1);
      verify(() => mockStorage.delete(key: 'app_lock_pin_salt')).called(1);
    });
  });
}
