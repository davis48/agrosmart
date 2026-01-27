import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:agriculture/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:agriculture/features/auth/data/models/user_model.dart';

// Mocks
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  // Données de test avec UserModel
  const tUserModel = UserModel(
    id: '1',
    nom: 'Koné',
    prenoms: 'Amadou',
    telephone: '0708091011',
    email: 'amadou@test.ci',
    role: 'PRODUCTEUR',
    token: 'test_token',
  );

  group('login', () {
    const tIdentifier = '0708091011';
    const tPassword = 'password123';

    test('should return User when login is successful', () async {
      // arrange
      when(
        () => mockRemoteDataSource.login(tIdentifier, tPassword),
      ).thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.login(tIdentifier, tPassword);

      // assert
      result.fold((failure) => fail('Should not return failure'), (user) {
        expect(user.id, tUserModel.id);
        expect(user.nom, tUserModel.nom);
      });
      verify(
        () => mockRemoteDataSource.login(tIdentifier, tPassword),
      ).called(1);
    });

    test(
      'should return ServerFailure when datasource throws ServerFailure',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.login(tIdentifier, tPassword),
        ).thenThrow(const ServerFailure('Identifiants incorrects'));

        // act
        final result = await repository.login(tIdentifier, tPassword);

        // assert
        expect(result, const Left(ServerFailure('Identifiants incorrects')));
      },
    );

    test(
      'should return ServerFailure with generic message on unexpected error',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.login(tIdentifier, tPassword),
        ).thenThrow(Exception('Unknown error'));

        // act
        final result = await repository.login(tIdentifier, tPassword);

        // assert
        result.fold(
          (failure) => expect(failure, isA<Failure>()),
          (_) => fail('Should return failure'),
        );
      },
    );
  });

  group('verifyOtp', () {
    const tIdentifier = '0708091011';
    const tCode = '123456';

    test('should return User when OTP verification is successful', () async {
      // arrange
      when(
        () => mockRemoteDataSource.verifyOtp(tIdentifier, tCode),
      ).thenAnswer((_) async => tUserModel);

      // act
      final result = await repository.verifyOtp(tIdentifier, tCode);

      // assert
      result.fold((failure) => fail('Should not return failure'), (user) {
        expect(user.id, tUserModel.id);
      });
      verify(
        () => mockRemoteDataSource.verifyOtp(tIdentifier, tCode),
      ).called(1);
    });

    test('should return ServerFailure when OTP is invalid', () async {
      // arrange
      when(
        () => mockRemoteDataSource.verifyOtp(tIdentifier, tCode),
      ).thenThrow(const ServerFailure('Code OTP invalide'));

      // act
      final result = await repository.verifyOtp(tIdentifier, tCode);

      // assert
      expect(result, const Left(ServerFailure('Code OTP invalide')));
    });
  });
}
