import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/parcelles/domain/repositories/parcelle_repository.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';

// Mock avec mocktail
class MockParcelleRepository extends Mock implements ParcelleRepository {}

void main() {
  late ParcelleBloc parcelleBloc;
  late MockParcelleRepository mockRepository;

  setUp(() {
    mockRepository = MockParcelleRepository();
    parcelleBloc = ParcelleBloc(repository: mockRepository);
  });

  tearDown(() {
    parcelleBloc.close();
  });

  // Données de test
  final testParcelles = [
    const Parcelle(
      id: '1',
      nom: 'Parcelle Test 1',
      superficie: 2.5,
      status: 'ACTIVE',
      typeSol: 'argileux',
      cultureLegacy: 'Manioc',
    ),
    const Parcelle(
      id: '2',
      nom: 'Parcelle Test 2',
      superficie: 1.0,
      status: 'EN_REPOS',
      typeSol: 'sableux',
      cultureLegacy: null,
    ),
  ];

  group('ParcelleBloc', () {
    test('état initial doit être ParcelleInitial', () {
      expect(parcelleBloc.state, isA<ParcelleInitial>());
    });

    group('LoadParcelles', () {
      blocTest<ParcelleBloc, ParcelleState>(
        'émet [ParcelleLoading, ParcelleLoaded] quand chargement réussit',
        build: () {
          when(
            () => mockRepository.getParcelles(),
          ).thenAnswer((_) async => testParcelles);
          return parcelleBloc;
        },
        act: (bloc) => bloc.add(const LoadParcelles()),
        expect: () => [isA<ParcelleLoading>(), isA<ParcelleLoaded>()],
        verify: (_) {
          verify(() => mockRepository.getParcelles()).called(1);
        },
      );

      blocTest<ParcelleBloc, ParcelleState>(
        'émet [ParcelleLoading, ParcelleError] quand chargement échoue',
        build: () {
          when(
            () => mockRepository.getParcelles(),
          ).thenThrow(Exception('Erreur réseau'));
          return parcelleBloc;
        },
        act: (bloc) => bloc.add(const LoadParcelles()),
        expect: () => [isA<ParcelleLoading>(), isA<ParcelleError>()],
      );

      blocTest<ParcelleBloc, ParcelleState>(
        'retourne liste vide quand aucune parcelle',
        build: () {
          when(() => mockRepository.getParcelles()).thenAnswer((_) async => []);
          return parcelleBloc;
        },
        act: (bloc) => bloc.add(const LoadParcelles()),
        expect: () => [
          isA<ParcelleLoading>(),
          predicate<ParcelleState>(
            (state) => state is ParcelleLoaded && state.parcelles.isEmpty,
          ),
        ],
      );
    });

    group('CreateParcelle', () {
      final newParcelleData = {
        'nom': 'Nouvelle Parcelle',
        'superficie': 3.0,
        'type_sol': 'limoneux',
        'culture_actuelle': 'Riz',
      };

      blocTest<ParcelleBloc, ParcelleState>(
        'émet [ParcelleLoading, ParcelleLoaded] après création réussie',
        build: () {
          when(() => mockRepository.createParcelle(any())).thenAnswer(
            (_) async => const Parcelle(
              id: '3',
              nom: 'Nouvelle Parcelle',
              superficie: 3.0,
              status: 'ACTIVE',
              typeSol: 'limoneux',
              cultureLegacy: 'Riz',
            ),
          );
          when(
            () => mockRepository.getParcelles(),
          ).thenAnswer((_) async => [...testParcelles]);
          return parcelleBloc;
        },
        act: (bloc) => bloc.add(CreateParcelle(newParcelleData)),
        expect: () => [isA<ParcelleLoading>(), isA<ParcelleLoaded>()],
        verify: (_) {
          verify(() => mockRepository.createParcelle(any())).called(1);
        },
      );

      blocTest<ParcelleBloc, ParcelleState>(
        'émet [ParcelleLoading, ParcelleError] quand création échoue',
        build: () {
          when(
            () => mockRepository.createParcelle(any()),
          ).thenThrow(Exception('Erreur création'));
          return parcelleBloc;
        },
        act: (bloc) => bloc.add(CreateParcelle(newParcelleData)),
        expect: () => [isA<ParcelleLoading>(), isA<ParcelleError>()],
      );
    });
  });

  group('ParcelleState Equatable', () {
    test('ParcelleInitial instances sont égales', () {
      expect(const ParcelleInitial(), equals(const ParcelleInitial()));
    });

    test('ParcelleLoading instances sont égales', () {
      expect(const ParcelleLoading(), equals(const ParcelleLoading()));
    });

    test('ParcelleLoaded avec mêmes parcelles sont égales', () {
      final state1 = ParcelleLoaded(testParcelles);
      final state2 = ParcelleLoaded(testParcelles);
      expect(state1, equals(state2));
    });

    test('ParcelleError avec même message sont égales', () {
      const state1 = ParcelleError('Erreur');
      const state2 = ParcelleError('Erreur');
      expect(state1, equals(state2));
    });
  });
}
