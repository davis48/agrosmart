# Documentation Technique - Agrosmart CI Mobile

> **Document de présentation technique**
> Dernière mise à jour : 18 janvier 2026

---

## 1. Vue d'Ensemble du Projet

**Agrosmart CI** est une application mobile d'agriculture intelligente destinée aux producteurs ivoiriens. Elle permet la gestion des parcelles agricoles, le monitoring IoT des capteurs, les prévisions météo, le diagnostic des maladies des plantes par IA, et un marketplace agricole.

| Élément | Valeur |
|---------|--------|
| **Nom** | Agrosmart CI |
| **Version** | 1.0.0+1 |
| **SDK Dart** | ^3.10.1 |
| **Plateformes** | Android, iOS, Web, Desktop (macOS, Windows, Linux) |

---

## 2. Architecture Logicielle

### 2.1 Pattern Architectural : Clean Architecture + BLoC

L'application utilise la **Clean Architecture** de Robert C. Martin combinée avec le pattern **BLoC (Business Logic Component)** pour la gestion d'état.

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │    Pages    │  │   Widgets   │  │    BLoCs    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  Entities   │  │  Use Cases  │  │ Repositories│ (abstract)
│  └─────────────┘  └─────────────┘  └─────────────┘          │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Models    │  │ Data Sources│  │ Repositories│ (impl)   │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Pourquoi Clean Architecture + BLoC ?

| Avantage | Description |
|----------|-------------|
| **Séparation des responsabilités** | Chaque couche a un rôle précis |
| **Testabilité** | Les couches peuvent être testées indépendamment |
| **Maintenabilité** | Modifications isolées sans effets de bord |
| **Scalabilité** | Ajout facile de nouvelles fonctionnalités |

### 2.3 Structure des Dossiers

```
lib/
├── core/                    # Éléments partagés
│   ├── error/              # Gestion des erreurs (Failure)
│   ├── network/            # API Client (Dio), NetworkInfo
│   ├── services/           # Services (Location, Voice)
│   ├── theme/              # Thèmes (Light/Dark)
│   ├── usecases/           # UseCase abstrait
│   └── widgets/            # Widgets réutilisables
│
├── features/               # Modules fonctionnels (22 features)
│   ├── auth/              # Authentification
│   ├── dashboard/         # Tableau de bord
│   ├── parcelles/         # Gestion des parcelles
│   ├── capteurs/          # Monitoring capteurs IoT
│   ├── weather/           # Météo
│   ├── diagnostic/        # Diagnostic IA maladies
│   ├── marketplace/       # Place de marché
│   ├── formations/        # Formations agricoles
│   ├── analytics/         # Statistiques
│   ├── notifications/     # Alertes
│   ├── community/         # Forum communautaire
│   ├── messages/          # Messagerie
│   ├── orders/            # Commandes
│   └── ...
│
├── l10n/                   # Internationalisation (FR, Dioula, Baoulé, Bété)
├── injection_container.dart # Injection de dépendances (GetIt)
└── main.dart               # Point d'entrée
```

### 2.4 Structure d'une Feature

Chaque feature suit cette organisation :

```
feature_name/
├── data/
│   ├── datasources/       # Sources de données (Remote/Local)
│   ├── models/            # Modèles JSON (extends Entity)
│   └── repositories/      # Implémentation des repositories
├── domain/
│   ├── entities/          # Entités métier pures
│   ├── repositories/      # Interfaces des repositories
│   └── usecases/          # Cas d'utilisation
└── presentation/
    ├── bloc/              # BLoC (Events + States)
    ├── pages/             # Écrans
    └── widgets/           # Widgets spécifiques
```

---

## 3. Technologies Utilisées

### 3.1 Frontend Mobile (Flutter)

| Technologie | Version | Rôle |
|-------------|---------|------|
| **Flutter** | 3.38.5 | Framework UI cross-platform |
| **Dart** | 3.10.4 | Langage de programmation |
| **flutter_bloc** | 9.1.1 | Gestion d'état (BLoC pattern) |
| **go_router** | 17.0.1 | Navigation déclarative |
| **dio** | 5.4.0 | Client HTTP |
| **get_it** | 9.2.0 | Injection de dépendances |
| **isar** | 4.0.0-dev.14 | Base de données locale (cache) |
| **freezed** | 2.4.6 | Génération de code immutable |
| **geolocator** | 14.0.1 | Géolocalisation GPS |
| **flutter_map** | 8.2.2 | Cartes interactives |
| **image_picker** | 1.1.2 | Capture photo (diagnostic) |
| **speech_to_text** | 7.0.0 | Reconnaissance vocale |
| **flutter_tts** | 4.2.3 | Synthèse vocale |

### 3.2 Backend (Node.js)

| Technologie | Version | Rôle |
|-------------|---------|------|
| **Node.js** | ≥18.0.0 | Runtime JavaScript |
| **Express** | 5.2.1 | Framework web REST API |
| **Prisma** | 5.22.0 | ORM (Object-Relational Mapping) |
| **JWT** | 9.0.3 | Authentification par tokens |
| **bcryptjs** | 3.0.3 | Hashage des mots de passe |
| **Socket.io** | 4.7.2 | Communication temps réel |
| **Redis** | (ioredis 5.8.2) | Cache et sessions |
| **BullMQ** | 5.66.1 | File d'attente de jobs |

### 3.3 Base de Données

| Composant | Technologie | Usage |
|-----------|-------------|-------|
| **Principal** | MySQL 8.x | Données persistantes |
| **ORM** | Prisma | Mapping objet-relationnel |
| **Cache** | Redis | Sessions, cache API |
| **Time-series** | InfluxDB | Données capteurs IoT |
| **Local (mobile)** | Isar | Cache offline |

### 3.4 Services Externes

| Service | Usage |
|---------|-------|
| **Twilio** | Envoi SMS (OTP) |
| **Nodemailer** | Envoi emails |
| **Open-Meteo API** | Données météorologiques |
| **Service IA Python** | Diagnostic maladies (TensorFlow) |

---

## 4. Base de Données - Schéma Principal

### 4.1 Modèles Prisma Principaux

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    User     │────<│   Parcelle  │────<│   Station   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                    │
       │                   │                    │
       ▼                   ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   OtpCode   │     │  Plantation │     │   Capteur   │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │   Mesure    │
                                        └─────────────┘
```

### 4.2 Énumérations Principales

| Enum | Valeurs |
|------|---------|
| **UserRole** | ADMIN, AGRONOME, PRODUCTEUR, FOURNISSEUR, CONSEILLER |
| **ParcelleStatus** | ACTIVE, EN_REPOS, PREPAREE, ENSEMENCEE, EN_CROISSANCE, RECOLTE |
| **ParcelleHealth** | OPTIMAL, SURVEILLANCE, CRITIQUE |
| **AlertLevel** | INFO, IMPORTANT, CRITIQUE |
| **CapteurType** | HUMIDITE_SOL, UV, NPK, DIRECTION_VENT, etc. |

---

## 5. API Backend - Endpoints Principaux

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/v1/auth/register` | Inscription |
| POST | `/api/v1/auth/login` | Connexion |
| GET | `/api/v1/auth/me` | Profil utilisateur |
| GET | `/api/v1/parcelles` | Liste des parcelles |
| POST | `/api/v1/parcelles` | Créer une parcelle |
| GET | `/api/v1/capteurs` | Liste des capteurs |
| GET | `/api/v1/weather/forecast` | Prévisions météo |
| POST | `/api/v1/diagnostic/analyze` | Analyse IA d'image |
| GET | `/api/v1/marketplace/products` | Produits marketplace |
| GET | `/api/v1/formations` | Liste des formations |
| GET | `/api/v1/analytics/summary` | Statistiques |

---

## 6. Fonctionnalités de l'Application

### 6.1 Liste des 22 Modules

| # | Module | Description |
|---|--------|-------------|
| 1 | **auth** | Authentification (login, register, OTP) |
| 2 | **dashboard** | Tableau de bord principal |
| 3 | **parcelles** | Gestion des parcelles agricoles |
| 4 | **capteurs** | Monitoring capteurs IoT |
| 5 | **weather** | Prévisions météorologiques |
| 6 | **diagnostic** | Diagnostic IA des maladies |
| 7 | **diagnostics** | Historique des diagnostics |
| 8 | **marketplace** | Place de marché agricole |
| 9 | **formations** | Formations et tutoriels |
| 10 | **analytics** | Statistiques et rapports |
| 11 | **notifications** | Système d'alertes |
| 12 | **community** | Forum communautaire |
| 13 | **messages** | Messagerie privée |
| 14 | **orders** | Gestion des commandes |
| 15 | **recommandations** | Conseils personnalisés |
| 16 | **profile** | Profil utilisateur |
| 17 | **settings** | Paramètres de l'app |
| 18 | **about** | À propos de l'application |
| 19 | **support** | Support client |
| 20 | **training** | Entraînement IA |
| 21 | **offline** | Mode hors-ligne |
| 22 | **common** | Composants partagés |

### 6.2 Fonctionnalités Clés

- ✅ **Authentification sécurisée** (JWT + OTP)
- ✅ **Gestion multi-parcelles** avec suivi santé
- ✅ **Monitoring IoT temps réel** (capteurs)
- ✅ **Prévisions météo localisées**
- ✅ **Diagnostic IA par photo** (maladies plantes)
- ✅ **Marketplace B2B/B2C**
- ✅ **Forum communautaire**
- ✅ **Assistant vocal** (TTS + STT)
- ✅ **Multi-langue** (Français, Dioula, Baoulé, Bété)
- ✅ **Mode sombre**
- ✅ **Cache offline** (Isar)

---

## 7. Injection de Dépendances

L'application utilise **GetIt** comme Service Locator pour l'injection de dépendances.

```dart
// Exemple d'enregistrement
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(remoteDataSource: sl()),
);

// Exemple d'utilisation
final authBloc = sl<AuthBloc>();
```

**Ordre d'enregistrement :**

1. Services externes (Storage, Network)
2. API Client (Dio)
3. Data Sources
4. Repositories
5. Use Cases
6. BLoCs

---

## 8. Gestion d'État avec BLoC

### 8.1 Flux de Données

```
┌─────────┐    Event    ┌─────────┐    State    ┌─────────┐
│   UI    │ ──────────> │  BLoC   │ ──────────> │   UI    │
└─────────┘             └─────────┘             └─────────┘
                             │
                             │ UseCase
                             ▼
                        ┌─────────┐
                        │  Repo   │
                        └─────────┘
```

### 8.2 Exemple : ParcelleBloc

```dart
// Events
abstract class ParcelleEvent {}
class LoadParcelles extends ParcelleEvent {}
class CreateParcelle extends ParcelleEvent {
  final Map<String, dynamic> data;
}

// States
abstract class ParcelleState {}
class ParcelleInitial extends ParcelleState {}
class ParcelleLoading extends ParcelleState {}
class ParcelleLoaded extends ParcelleState {
  final List<Parcelle> parcelles;
}
class ParcelleError extends ParcelleState {
  final String message;
}
```

---

## 9. Commandes Flutter Essentielles

### 9.1 Installation et Configuration

```bash
# Vérifier l'installation Flutter
flutter doctor -v

# Installer les dépendances
flutter pub get

# Générer le code (freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Nettoyer le projet
flutter clean
```

### 9.2 Exécution

```bash
# Lister les appareils disponibles
flutter devices

# Lister les émulateurs
flutter emulators

# Lancer un émulateur
flutter emulators --launch <emulator_id>

# Exécuter en mode debug
flutter run

# Exécuter sur un appareil spécifique
flutter run -d <device_id>

# Hot reload (dans le terminal flutter run)
r

# Hot restart
R

# Arrêter l'application
q
```

### 9.3 Build et Release

```bash
# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release

# Build iOS (macOS uniquement)
flutter build ios --release

# Build Web
flutter build web --release
```

### 9.4 Tests

```bash
# Exécuter tous les tests
flutter test

# Exécuter un fichier de test spécifique
flutter test test/widget_test.dart

# Tests avec couverture
flutter test --coverage
```

### 9.5 Analyse et Qualité

```bash
# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Vérifier les dépendances obsolètes
flutter pub outdated

# Mettre à jour les dépendances
flutter pub upgrade
```

### 9.6 Localisation

```bash
# Générer les fichiers de localisation
flutter gen-l10n
```

### 9.7 Commandes Utiles

```bash
# Voir les logs en temps réel
flutter logs

# Capturer une screenshot
flutter screenshot

# Inspecter les widgets (DevTools)
flutter pub global activate devtools
flutter pub global run devtools

# Créer une icône d'app (si flutter_launcher_icons configuré)
flutter pub run flutter_launcher_icons
```

---

## 10. Configuration des Environnements

### 10.1 API Base URL

```dart
// lib/core/network/api_client.dart
final dioClient = Dio(BaseOptions(
  baseUrl: Platform.isAndroid 
      ? 'http://10.0.2.2:3000/api/v1'  // Émulateur Android
      : 'http://localhost:3000/api/v1', // iOS/Desktop
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));
```

### 10.2 Pour la Production

Modifier `baseUrl` pour pointer vers le serveur de production :

```dart
baseUrl: 'https://api.agrosmart-ci.com/api/v1'
```

---

## 11. Démarrage Rapide

### Prérequis

- Flutter SDK 3.38.5+
- Android Studio / Xcode
- Un émulateur ou appareil physique

### Étapes

```bash
# 1. Cloner le projet
git clone <repo_url>
cd agriculture/mobile

# 2. Installer les dépendances
flutter pub get

# 3. Générer le code
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Lancer le backend (dans un autre terminal)
cd ../backend
npm install
npm run dev

# 5. Lancer l'application mobile
flutter run
```

---

## 12. Résumé de l'Architecture

| Couche | Responsabilité | Exemples |
|--------|---------------|----------|
| **Presentation** | UI, Interactions utilisateur | Pages, Widgets, BLoCs |
| **Domain** | Logique métier pure | Entities, UseCases, Repository interfaces |
| **Data** | Accès aux données | Models, DataSources, Repository implementations |
| **Core** | Utilitaires partagés | Network, Themes, Services |

---

## 13. Points Forts Techniques

1. **Architecture propre** : Séparation nette entre les couches
2. **Testabilité** : Injection de dépendances, interfaces abstraites
3. **Scalabilité** : Structure modulaire par features
4. **Performance** : Cache local (Isar), lazy loading
5. **UX** : Mode offline, thème sombre, multi-langue
6. **Sécurité** : JWT, stockage sécurisé, validation côté serveur

---

*Document généré pour la présentation technique du projet Agrosmart CI*
