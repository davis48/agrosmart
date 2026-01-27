import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/features/auth/domain/usecases/login.dart';
import 'package:agriculture/features/auth/domain/usecases/verify_otp.dart';
import 'package:agriculture/features/auth/domain/usecases/register.dart';
import 'package:agriculture/features/auth/domain/usecases/update_profile.dart';
import 'package:agriculture/features/auth/domain/entities/user.dart';
import 'package:agriculture/core/error/failures.dart';

// Mocks utilisant mocktail
class MockLogin extends Mock implements Login {}

class MockVerifyOtp extends Mock implements VerifyOtp {}

class MockRegister extends Mock implements Register {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

// Fake pour LoginParams
class FakeLoginParams extends Fake implements LoginParams {}

class FakeVerifyOtpParams extends Fake implements VerifyOtpParams {}

class FakeRegisterParams extends Fake implements RegisterParams {}

void main() {
  late AuthBloc authBloc;
  late MockLogin mockLogin;
  late MockVerifyOtp mockVerifyOtp;
  late MockRegister mockRegister;
  late MockUpdateProfile mockUpdateProfile;

  setUpAll(() {
    registerFallbackValue(FakeLoginParams());
    registerFallbackValue(FakeVerifyOtpParams());
    registerFallbackValue(FakeRegisterParams());
  });

  setUp(() {
    mockLogin = MockLogin();
    mockVerifyOtp = MockVerifyOtp();
    mockRegister = MockRegister();
    mockUpdateProfile = MockUpdateProfile();

    authBloc = AuthBloc(
      login: mockLogin,
      verifyOtp: mockVerifyOtp,
      register: mockRegister,
      updateProfile: mockUpdateProfile,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  // User de test
  const testUser = User(
    id: '1',
    nom: 'Test',
    prenoms: 'User',
    telephone: '+22500000000',
    email: 'test@example.com',
    role: 'PRODUCTEUR',
  );

  group('AuthBloc', () {
    test('état initial doit être AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('LoginRequested', () {
      const testIdentifier = '+22500000000';
      const testPassword = 'password123';

      blocTest<AuthBloc, AuthState>(
        'émet [AuthLoading, AuthAuthenticated] quand login réussit',
        build: () {
          when(
            () => mockLogin(any()),
          ).thenAnswer((_) async => const Right(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginRequested(testIdentifier, testPassword)),
        expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
        verify: (_) {
          verify(() => mockLogin(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'émet [AuthLoading, AuthError] quand login échoue',
        build: () {
          when(() => mockLogin(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Identifiants invalides')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginRequested(testIdentifier, testPassword)),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('VerifyOtpRequested', () {
      const testIdentifier = '+22500000000';
      const testOtp = '123456';

      blocTest<AuthBloc, AuthState>(
        'émet [AuthLoading, AuthAuthenticated] quand OTP valide',
        build: () {
          when(
            () => mockVerifyOtp(any()),
          ).thenAnswer((_) async => const Right(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(VerifyOtpRequested(testIdentifier, testOtp)),
        expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
        verify: (_) {
          verify(() => mockVerifyOtp(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'émet [AuthLoading, AuthError] quand OTP invalide',
        build: () {
          when(() => mockVerifyOtp(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Code OTP invalide')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(VerifyOtpRequested(testIdentifier, testOtp)),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });

    group('RegisterRequested', () {
      blocTest<AuthBloc, AuthState>(
        'émet [AuthLoading, AuthRegistered] quand inscription réussit',
        build: () {
          when(
            () => mockRegister(any()),
          ).thenAnswer((_) async => const Right(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(
          RegisterRequested(
            nom: 'Test',
            prenoms: 'User',
            telephone: '+22500000000',
            password: 'password123',
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthRegistered>()],
      );

      blocTest<AuthBloc, AuthState>(
        'émet [AuthLoading, AuthError] quand inscription échoue',
        build: () {
          when(() => mockRegister(any())).thenAnswer(
            (_) async => const Left(ServerFailure('Numéro déjà utilisé')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(
          RegisterRequested(
            nom: 'Test',
            prenoms: 'User',
            telephone: '+22500000000',
            password: 'password123',
          ),
        ),
        expect: () => [isA<AuthLoading>(), isA<AuthError>()],
      );
    });
  });
}
