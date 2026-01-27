import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/core/usecases/usecase.dart';
import 'package:agriculture/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:agriculture/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:agriculture/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Mocks
class MockGetDashboardData extends Mock implements GetDashboardData {}

void main() {
  late DashboardBloc dashboardBloc;
  late MockGetDashboardData mockGetDashboardData;

  setUp(() {
    mockGetDashboardData = MockGetDashboardData();
    dashboardBloc = DashboardBloc(getDashboardData: mockGetDashboardData);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  // Données de test
  const tWeather = Weather(
    temperature: 28.5,
    humidity: 75.0,
    description: 'Ensoleillé',
    icon: 'sunny',
  );

  const tStats = Stats(yield: 4500.0, roi: 15.5, soilHealth: 85.0);

  const tAlerts = [
    Alert(
      id: '1',
      title: 'Alerte sécheresse',
      message: 'Niveau d\'eau bas sur la parcelle A',
      level: 'warning',
    ),
    Alert(
      id: '2',
      title: 'Humidité élevée',
      message: 'Risque de maladies fongiques',
      level: 'info',
    ),
  ];

  const tDashboardData = DashboardData(
    weather: tWeather,
    stats: tStats,
    alerts: tAlerts,
  );

  group('DashboardBloc', () {
    test('initial state should be DashboardInitial', () {
      expect(dashboardBloc.state, isA<DashboardInitial>());
    });

    group('LoadDashboard', () {
      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardLoaded] when successful',
        build: () {
          when(
            () => mockGetDashboardData(NoParams()),
          ).thenAnswer((_) async => const Right(tDashboardData));
          return dashboardBloc;
        },
        act: (bloc) => bloc.add(LoadDashboard()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (state) => state.data,
            'data',
            tDashboardData,
          ),
        ],
        verify: (_) {
          verify(() => mockGetDashboardData(NoParams())).called(1);
        },
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when fetch fails',
        build: () {
          when(
            () => mockGetDashboardData(NoParams()),
          ).thenAnswer((_) async => Left(ServerFailure('Erreur serveur')));
          return dashboardBloc;
        },
        act: (bloc) => bloc.add(LoadDashboard()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (state) => state.message,
            'message',
            'Erreur serveur',
          ),
        ],
      );

      blocTest<DashboardBloc, DashboardState>(
        'emits [DashboardLoading, DashboardError] when network fails',
        build: () {
          when(
            () => mockGetDashboardData(NoParams()),
          ).thenAnswer((_) async => Left(NetworkFailure('Pas de connexion')));
          return dashboardBloc;
        },
        act: (bloc) => bloc.add(LoadDashboard()),
        expect: () => [
          isA<DashboardLoading>(),
          isA<DashboardError>().having(
            (state) => state.message,
            'message',
            'Pas de connexion',
          ),
        ],
      );
    });

    group('State equality', () {
      test('DashboardLoaded states with same data are equal', () {
        expect(
          DashboardLoaded(tDashboardData),
          equals(DashboardLoaded(tDashboardData)),
        );
      });

      test('DashboardLoaded states with different data are not equal', () {
        const differentData = DashboardData(
          weather: tWeather,
          stats: Stats(yield: 0, roi: 0, soilHealth: 0),
          alerts: [],
        );
        expect(
          DashboardLoaded(tDashboardData),
          isNot(equals(DashboardLoaded(differentData))),
        );
      });

      test('DashboardError states with same message are equal', () {
        expect(DashboardError('error'), equals(DashboardError('error')));
      });
    });
  });
}
