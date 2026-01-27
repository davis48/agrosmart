import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/marketplace/domain/entities/product.dart';
import 'package:agriculture/features/marketplace/domain/usecases/get_products.dart';
import 'package:agriculture/features/marketplace/domain/usecases/create_product.dart';
import 'package:agriculture/features/marketplace/presentation/bloc/marketplace_bloc.dart';

// Mocks
class MockGetProducts extends Mock implements GetProducts {}

class MockCreateProduct extends Mock implements CreateProduct {}

void main() {
  late MarketplaceBloc marketplaceBloc;
  late MockGetProducts mockGetProducts;
  late MockCreateProduct mockCreateProduct;

  setUp(() {
    mockGetProducts = MockGetProducts();
    mockCreateProduct = MockCreateProduct();
    marketplaceBloc = MarketplaceBloc(
      getProducts: mockGetProducts,
      createProduct: mockCreateProduct,
    );
  });

  tearDown(() {
    marketplaceBloc.close();
  });

  // Données de test
  final tProducts = [
    Product(
      id: '1',
      nom: 'Engrais NPK',
      description: 'Engrais complet pour toutes cultures',
      categorie: 'engrais',
      prix: 15000.0,
      unite: 'sac 50kg',
      quantiteDisponible: 100.0,
      localisation: 'Abidjan',
      images: ['https://example.com/engrais.jpg'],
      vendeurId: 'vendor1',
      vendeurNom: 'AgriShop CI',
      vendeurTelephone: '+225 0123456789',
      createdAt: DateTime(2024, 1, 15),
    ),
    Product(
      id: '2',
      nom: 'Semences de maïs',
      description: 'Variété améliorée résistante à la sécheresse',
      categorie: 'semences',
      prix: 5000.0,
      unite: 'kg',
      quantiteDisponible: 500.0,
      localisation: 'Bouaké',
      images: ['https://example.com/mais.jpg'],
      vendeurId: 'vendor2',
      vendeurNom: 'SemencesPro',
      createdAt: DateTime(2024, 1, 10),
    ),
  ];

  group('MarketplaceBloc', () {
    test('initial state should be MarketplaceInitial', () {
      expect(marketplaceBloc.state, isA<MarketplaceInitial>());
    });

    group('LoadMarketplaceProducts', () {
      blocTest<MarketplaceBloc, MarketplaceState>(
        'emits [MarketplaceLoading, MarketplaceLoaded] when products fetch succeeds',
        build: () {
          when(
            () => mockGetProducts(1),
          ).thenAnswer((_) async => Right(tProducts));
          return marketplaceBloc;
        },
        act: (bloc) => bloc.add(LoadMarketplaceProducts()),
        expect: () => [
          isA<MarketplaceLoading>(),
          isA<MarketplaceLoaded>().having(
            (state) => state.products,
            'products',
            tProducts,
          ),
        ],
        verify: (_) {
          verify(() => mockGetProducts(1)).called(1);
        },
      );

      blocTest<MarketplaceBloc, MarketplaceState>(
        'emits [MarketplaceLoading, MarketplaceError] when products fetch fails',
        build: () {
          when(
            () => mockGetProducts(1),
          ).thenAnswer((_) async => Left(ServerFailure('Erreur serveur')));
          return marketplaceBloc;
        },
        act: (bloc) => bloc.add(LoadMarketplaceProducts()),
        expect: () => [isA<MarketplaceLoading>(), isA<MarketplaceError>()],
      );

      blocTest<MarketplaceBloc, MarketplaceState>(
        'emits [MarketplaceLoading, MarketplaceError] when exception occurs',
        build: () {
          when(
            () => mockGetProducts(1),
          ).thenThrow(Exception('Unexpected error'));
          return marketplaceBloc;
        },
        act: (bloc) => bloc.add(LoadMarketplaceProducts()),
        expect: () => [
          isA<MarketplaceLoading>(),
          isA<MarketplaceError>().having(
            (state) => state.message,
            'message',
            'Une erreur inattendue est survenue.',
          ),
        ],
      );
    });

    group('State equality', () {
      test('MarketplaceLoaded states with same products are equal', () {
        expect(
          MarketplaceLoaded(products: tProducts),
          equals(MarketplaceLoaded(products: tProducts)),
        );
      });

      test(
        'MarketplaceLoaded states with different products are not equal',
        () {
          expect(
            MarketplaceLoaded(products: tProducts),
            isNot(equals(const MarketplaceLoaded(products: []))),
          );
        },
      );

      test('MarketplaceError states with same message are equal', () {
        expect(
          const MarketplaceError(message: 'error'),
          equals(const MarketplaceError(message: 'error')),
        );
      });

      test('MarketplaceError states with different messages are not equal', () {
        expect(
          const MarketplaceError(message: 'error1'),
          isNot(equals(const MarketplaceError(message: 'error2'))),
        );
      });
    });

    group('Event equality', () {
      test('LoadMarketplaceProducts events are equal', () {
        expect(LoadMarketplaceProducts(), equals(LoadMarketplaceProducts()));
      });
    });
  });
}
