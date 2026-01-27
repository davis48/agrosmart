import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:agriculture/core/services/secure_storage_service.dart';

// Mock pour FlutterSecureStorage
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageService service;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('Token Management', () {
    const tAccessToken = 'access_token_123';
    const tRefreshToken = 'refresh_token_456';

    group('saveAccessToken', () {
      test('should write access token to secure storage', () async {
        // arrange
        when(
          () => mockStorage.write(key: 'access_token', value: tAccessToken),
        ).thenAnswer((_) async {});

        // act
        await service.saveAccessToken(tAccessToken);

        // assert
        verify(
          () => mockStorage.write(key: 'access_token', value: tAccessToken),
        ).called(1);
      });
    });

    group('getAccessToken', () {
      test('should return access token from secure storage', () async {
        // arrange
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => tAccessToken);

        // act
        final result = await service.getAccessToken();

        // assert
        expect(result, tAccessToken);
      });

      test('should return null when no token stored', () async {
        // arrange
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => null);

        // act
        final result = await service.getAccessToken();

        // assert
        expect(result, null);
      });
    });

    group('saveRefreshToken', () {
      test('should write refresh token to secure storage', () async {
        // arrange
        when(
          () => mockStorage.write(key: 'refresh_token', value: tRefreshToken),
        ).thenAnswer((_) async {});

        // act
        await service.saveRefreshToken(tRefreshToken);

        // assert
        verify(
          () => mockStorage.write(key: 'refresh_token', value: tRefreshToken),
        ).called(1);
      });
    });

    group('getRefreshToken', () {
      test('should return refresh token from secure storage', () async {
        // arrange
        when(
          () => mockStorage.read(key: 'refresh_token'),
        ).thenAnswer((_) async => tRefreshToken);

        // act
        final result = await service.getRefreshToken();

        // assert
        expect(result, tRefreshToken);
      });
    });

    group('saveTokens', () {
      test('should save both tokens when refresh token provided', () async {
        // arrange
        when(
          () => mockStorage.write(key: 'access_token', value: tAccessToken),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.write(key: 'refresh_token', value: tRefreshToken),
        ).thenAnswer((_) async {});

        // act
        await service.saveTokens(
          accessToken: tAccessToken,
          refreshToken: tRefreshToken,
        );

        // assert
        verify(
          () => mockStorage.write(key: 'access_token', value: tAccessToken),
        ).called(1);
        verify(
          () => mockStorage.write(key: 'refresh_token', value: tRefreshToken),
        ).called(1);
      });

      test(
        'should only save access token when refresh token is null',
        () async {
          // arrange
          when(
            () => mockStorage.write(key: 'access_token', value: tAccessToken),
          ).thenAnswer((_) async {});

          // act
          await service.saveTokens(accessToken: tAccessToken);

          // assert
          verify(
            () => mockStorage.write(key: 'access_token', value: tAccessToken),
          ).called(1);
          verifyNever(
            () => mockStorage.write(
              key: 'refresh_token',
              value: any(named: 'value'),
            ),
          );
        },
      );
    });

    group('clearTokens', () {
      test('should delete both access and refresh tokens', () async {
        // arrange
        when(
          () => mockStorage.delete(key: 'access_token'),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.delete(key: 'refresh_token'),
        ).thenAnswer((_) async {});

        // act
        await service.clearTokens();

        // assert
        verify(() => mockStorage.delete(key: 'access_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      });
    });

    group('hasAccessToken', () {
      test('should return true when token exists and is not empty', () async {
        // arrange
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => tAccessToken);

        // act
        final result = await service.hasAccessToken();

        // assert
        expect(result, true);
      });

      test('should return false when token is null', () async {
        // arrange
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => null);

        // act
        final result = await service.hasAccessToken();

        // assert
        expect(result, false);
      });

      test('should return false when token is empty', () async {
        // arrange
        when(
          () => mockStorage.read(key: 'access_token'),
        ).thenAnswer((_) async => '');

        // act
        final result = await service.hasAccessToken();

        // assert
        expect(result, false);
      });
    });
  });

  group('User Data', () {
    const tUserId = 'user_123';

    group('saveUserId', () {
      test('should write user id to secure storage', () async {
        // arrange
        when(
          () => mockStorage.write(key: 'user_id', value: tUserId),
        ).thenAnswer((_) async {});

        // act
        await service.saveUserId(tUserId);

        // assert
        verify(
          () => mockStorage.write(key: 'user_id', value: tUserId),
        ).called(1);
      });
    });
  });
}
