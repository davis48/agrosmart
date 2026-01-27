# Plan de Consolidation: diagnostic/ vs diagnostics/

## Problème Identifié (M-ARC-01)

Il existe deux features quasi-identiques:
- `features/diagnostic/` - Utilisé par main.dart et routes principales
- `features/diagnostics/` - Utilisé par injection_container.dart et routes_example.dart

## Analyse des Différences

### Structure diagnostic/ (Actif)
```
diagnostic/
├── data/
│   ├── datasources/diagnostics_remote_data_source.dart
│   ├── models/diagnostic_model.dart
│   └── repositories/diagnostic_repository_impl.dart
├── domain/
│   ├── entities/diagnostic.dart (required fields)
│   ├── repositories/
│   └── services/diagnostic_storage_service.dart
└── presentation/
    ├── bloc/diagnostic_bloc.dart
    ├── pages/
    │   ├── diagnostic_page.dart (598 lines)
    │   ├── diagnostic_history_page.dart
    │   └── diagnostic_detail_page.dart
    └── widgets/diagnostic_analysis_table.dart
```

### Structure diagnostics/ (Legacy)
```
diagnostics/
├── data/
│   ├── datasources/diagnostic_remote_datasource.dart
│   └── repositories/diagnostics_repository_impl.dart
├── domain/
│   ├── entities/diagnostic.dart (nullable fields)
│   ├── repositories/diagnostics_repository.dart
│   └── usecases/
│       ├── analyze_plant.dart
│       └── get_diagnostics_history.dart
└── presentation/
    ├── bloc/diagnostics_bloc.dart
    └── pages/
        ├── diagnostic_page.dart (491 lines)
        ├── diagnostic_maladie_page.dart
        └── diagnostics_history_page.dart
```

## Imports Affectés

### Utilisant diagnostic/ (à conserver):
- `main.dart` - Routes principales
- `recommandation_bloc.dart` - Service de stockage
- `injection_container.dart` (lignes 91-94)

### Utilisant diagnostics/ (à migrer):
- `routes_example.dart` - Exemple de routes
- `injection_container.dart` (lignes 31-36)

## Plan de Migration Recommandé

### Phase 1: Préparer
1. ✅ Documenter les différences (ce fichier)
2. Créer des tests pour les deux features
3. Identifier toutes les références

### Phase 2: Unifier les Entités
```dart
// Target: diagnostic/domain/entities/diagnostic.dart
class Diagnostic extends Equatable {
  final String id;
  final String? diseaseName;      // Nullable pour compatibilité
  final String? cropType;
  final double? confidenceScore;
  final String? severity;
  final String? imageUrl;
  final String? recommendations;
  final String? treatmentSuggestions;
  final DateTime? createdAt;
  
  // Factory constructors for backward compatibility
  factory Diagnostic.fromRequiredFields(...) {}
}
```

### Phase 3: Migrer les Usecases
Copier depuis diagnostics/ vers diagnostic/:
- `analyze_plant.dart`
- `get_diagnostics_history.dart`

### Phase 4: Mettre à jour les Imports
1. Modifier routes_example.dart
2. Modifier injection_container.dart
3. Supprimer diagnostics/

### Phase 5: Nettoyer
1. Supprimer le dossier diagnostics/
2. Mettre à jour la documentation
3. Vérifier les tests

## Risques
- Breaking changes potentiels
- Tests à mettre à jour
- Routing à vérifier

## Décision
**Conserver `diagnostic/` comme feature principale** car:
- Plus complet (storage service, widgets)
- Utilisé par main.dart (routes actives)
- DiagnosticBloc plus récent avec tests

## Actions Immédiates
Pour éviter la confusion, ajouter un deprecation notice dans diagnostics/:

```dart
// @deprecated Use features/diagnostic/ instead
// This feature will be removed in the next major version
```
