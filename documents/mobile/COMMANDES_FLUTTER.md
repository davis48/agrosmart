# Commandes Flutter - Agrosmart CI

> **Guide de référence rapide des commandes Flutter**
> Pour le projet Agrosmart CI Mobile

---

## 🚀 Démarrage Rapide

```bash
# Aller dans le dossier mobile
cd /Users/amalamanemmanueljeandavid/Documents/Developement/agriculture/mobile

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

---

## 📋 Commandes par Catégorie

### 1. Configuration et Diagnostic

| Commande | Description |
|----------|-------------|
| `flutter doctor` | Vérifier l'installation Flutter |
| `flutter doctor -v` | Diagnostic détaillé |
| `flutter --version` | Version de Flutter |
| `flutter channel` | Voir le channel actuel (stable/beta/dev) |

### 2. Gestion des Dépendances

| Commande | Description |
|----------|-------------|
| `flutter pub get` | Installer les dépendances |
| `flutter pub upgrade` | Mettre à jour les dépendances |
| `flutter pub outdated` | Voir les dépendances obsolètes |
| `flutter pub cache clean` | Nettoyer le cache des packages |

### 3. Génération de Code

| Commande | Description |
|----------|-------------|
| `flutter pub run build_runner build` | Générer le code (freezed, json) |
| `flutter pub run build_runner build --delete-conflicting-outputs` | Regénérer en supprimant les conflits |
| `flutter pub run build_runner watch` | Générer en mode watch |
| `flutter gen-l10n` | Générer les fichiers de localisation |

### 4. Exécution et Debug

| Commande | Description |
|----------|-------------|
| `flutter run` | Lancer en mode debug |
| `flutter run -d <device_id>` | Lancer sur un appareil spécifique |
| `flutter run --release` | Lancer en mode release |
| `flutter run --profile` | Lancer en mode profile |
| `flutter attach` | Se connecter à une app en cours |

### 5. Commandes In-Terminal (pendant flutter run)

| Touche | Action |
|--------|--------|
| `r` | Hot Reload |
| `R` | Hot Restart |
| `q` | Quitter |
| `p` | Toggle debug paint |
| `o` | Toggle platform (iOS/Android) |
| `s` | Screenshot |
| `v` | Ouvrir DevTools |

### 6. Appareils et Émulateurs

| Commande | Description |
|----------|-------------|
| `flutter devices` | Lister les appareils connectés |
| `flutter emulators` | Lister les émulateurs disponibles |
| `flutter emulators --launch <id>` | Lancer un émulateur |
| `flutter emulators --create --name <nom>` | Créer un émulateur |

### 7. Build et Release

| Commande | Description |
|----------|-------------|
| `flutter build apk` | Build APK release |
| `flutter build apk --debug` | Build APK debug |
| `flutter build apk --split-per-abi` | Build APK par architecture |
| `flutter build appbundle` | Build App Bundle (Google Play) |
| `flutter build ios` | Build iOS |
| `flutter build web` | Build Web |
| `flutter build macos` | Build macOS |
| `flutter build windows` | Build Windows |
| `flutter build linux` | Build Linux |

### 8. Tests

| Commande | Description |
|----------|-------------|
| `flutter test` | Exécuter tous les tests |
| `flutter test test/widget_test.dart` | Un fichier spécifique |
| `flutter test --coverage` | Avec rapport de couverture |
| `flutter drive` | Tests d'intégration |

### 9. Analyse et Qualité

| Commande | Description |
|----------|-------------|
| `flutter analyze` | Analyser le code |
| `dart format lib/` | Formater le code |
| `dart fix --apply` | Appliquer les corrections auto |

### 10. Nettoyage

| Commande | Description |
|----------|-------------|
| `flutter clean` | Nettoyer le projet |
| `rm -rf build/` | Supprimer le dossier build |
| `rm -rf .dart_tool/` | Supprimer le cache Dart |

### 11. Logs et Debug

| Commande | Description |
|----------|-------------|
| `flutter logs` | Voir les logs en temps réel |
| `flutter screenshot` | Capture d'écran |
| `flutter pub global run devtools` | Ouvrir DevTools |

### 12. Localisation (i18n)

| Commande | Description |
|----------|-------------|
| `flutter gen-l10n` | Générer les fichiers ARB |

---

## 🎯 Workflow Quotidien

### Matin - Démarrer le développement

```bash
cd agriculture/mobile
flutter pub get
flutter run
```

### Après modification de modèles (freezed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Avant un commit

```bash
flutter analyze
dart format lib/
flutter test
```

### Pour une release

```bash
flutter clean
flutter pub get
flutter build apk --release
# ou
flutter build appbundle --release
```

---

## 🐛 Dépannage Courant

### L'émulateur ne se lance pas

```bash
flutter emulators
flutter emulators --launch Fresh_Pixel_API_34
```

### Problème de dépendances

```bash
flutter clean
flutter pub cache clean
flutter pub get
```

### Erreur de génération de code

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### ADB ne répond pas

```bash
~/Library/Android/sdk/platform-tools/adb kill-server
~/Library/Android/sdk/platform-tools/adb start-server
flutter devices
```

---

## 📱 Configuration Spécifique au Projet

### Backend Local

```bash
# Terminal 1 - Backend
cd agriculture/backend
npm run dev

# Terminal 2 - Mobile
cd agriculture/mobile
flutter run
```

### URL API

- **Émulateur Android** : `http://10.0.2.2:3000/api/v1`
- **iOS Simulator** : `http://localhost:3000/api/v1`
- **Appareil physique** : `http://<IP_MACHINE>:3000/api/v1`

---

## 📦 Fichiers Générés à Connaître

| Fichier | Généré par |
|---------|-----------|
| `*.g.dart` | json_serializable |
| `*.freezed.dart` | freezed |
| `app_localizations*.dart` | flutter gen-l10n |

---

*Référence rapide pour le développement Agrosmart CI*
