# AgroSmart - Test Configuration

## Structure des tests

```
test/
├── helpers/
│   └── test_helpers.dart      # Utilitaires et fixtures partagés
├── unit/
│   ├── blocs/                 # Tests unitaires des BLoCs
│   │   ├── auth_bloc_test.dart
│   │   ├── parcelle_bloc_test.dart
│   │   ├── dashboard_bloc_test.dart
│   │   ├── marketplace_bloc_test.dart
│   │   └── diagnostic_bloc_test.dart
│   ├── repositories/          # Tests des repositories (avec mocks)
│   └── services/              # Tests des services
├── widget/                    # Tests de widgets
│   ├── pages/
│   └── components/
└── integration/               # Tests d'intégration
    └── flows/
```

## Exécution des tests

### Tous les tests
```bash
flutter test
```

### Tests unitaires seulement
```bash
flutter test test/unit/
```

### Tests avec couverture
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Tests d'un fichier spécifique
```bash
flutter test test/unit/blocs/auth_bloc_test.dart
```

## Dépendances de test

Assurez-vous que ces packages sont dans `dev_dependencies` du `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  mockito: ^5.4.4
  build_runner: ^2.4.8
  mocktail: ^1.0.1
```

## Génération des mocks

Après avoir ajouté les annotations `@GenerateMocks`, exécutez:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Conventions de test

1. **Nommage**: `[nom_fichier]_test.dart`
2. **Structure**: Utiliser `group()` pour organiser les tests
3. **BlocTest**: Utiliser `blocTest()` de `bloc_test` package
4. **Mocks**: Utiliser Mockito avec `@GenerateMocks` annotation
5. **Fixtures**: Centraliser dans `test/helpers/test_helpers.dart`

## Couverture cible

| Composant | Couverture cible |
|-----------|------------------|
| BLoCs     | 90%              |
| Repositories | 80%           |
| Services  | 85%              |
| Widgets   | 70%              |
| Overall   | 80%              |
