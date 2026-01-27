# Documentation Base de Données - Agrosmart CI

> **Documentation complète de l'architecture de la base de données**
> Dernière mise à jour : 18 janvier 2026

---

## 1. Vue d'Ensemble

### 1.1 Informations Générales

| Élément | Valeur |
|---------|--------|
| **SGBD** | MySQL 8.x |
| **ORM** | Prisma 5.22.0 |
| **Nombre de tables** | 41 tables |
| **Nombre d'énumérations** | 13 enums |
| **Schéma** | `backend/prisma/schema.prisma` |

### 1.2 Configuration de Connexion

```javascript
// Connexion via variable d'environnement
DATABASE_URL="mysql://user:password@host:3306/agrosmart_db"
```

### 1.3 Autres Bases de Données Utilisées

| Base | Usage | Technologie |
|------|-------|-------------|
| **Redis** | Cache, sessions, files d'attente | In-memory |
| **InfluxDB** | Données time-series (capteurs IoT) | Time-series DB |
| **Isar** | Cache local mobile (offline) | NoSQL embarqué |

---

## 2. Architecture Relationnelle

### 2.1 Diagramme des Relations Principales

```
┌─────────────────────────────────────────────────────────────────┐
│                         UTILISATEURS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    ┌──────────┐         ┌──────────┐         ┌──────────┐       │
│    │  Region  │◄────────│   User   │────────►│ OtpCode  │       │
│    └──────────┘         └──────────┘         └──────────┘       │
│         │                    │                                   │
│         ▼                    │                                   │
│    ┌──────────┐              │                                   │
│    │Cooperative│             │                                   │
│    └──────────┘              │                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   AGRICULTURE   │  │   MARKETPLACE   │  │   FORMATIONS    │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│                 │  │                 │  │                 │
│  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │
│  │ Parcelle │   │  │  │ Produit  │   │  │  │Formation │   │
│  └──────────┘   │  │  └──────────┘   │  │  └──────────┘   │
│       │         │  │       │         │  │       │         │
│       ▼         │  │       ▼         │  │       ▼         │
│  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │
│  │ Station  │   │  │  │ Commande │   │  │  │  Module  │   │
│  └──────────┘   │  │  └──────────┘   │  │  └──────────┘   │
│       │         │  │       │         │  │       │         │
│       ▼         │  │       ▼         │  │       ▼         │
│  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │
│  │ Capteur  │   │  │  │Transaction│  │  │  │Progression│  │
│  └──────────┘   │  │  └──────────┘   │  │  └──────────┘   │
│       │         │  │                 │  │                 │
│       ▼         │  │                 │  │                 │
│  ┌──────────┐   │  │                 │  │                 │
│  │  Mesure  │   │  │                 │  │                 │
│  └──────────┘   │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## 3. Énumérations (Enums)

Les énumérations définissent les valeurs possibles pour certains champs.

### 3.1 Rôles et Statuts Utilisateur

| Enum | Valeurs | Description |
|------|---------|-------------|
| **UserRole** | `ADMIN`, `AGRONOME`, `PRODUCTEUR`, `FOURNISSEUR`, `CONSEILLER`, `PARTENAIRE` | Type d'utilisateur |
| **UserStatus** | `ACTIF`, `INACTIF`, `SUSPENDU`, `EN_ATTENTE` | État du compte |
| **OtpType** | `LOGIN`, `REGISTER`, `RESET` | Type de code OTP |

### 3.2 Parcelles et Agriculture

| Enum | Valeurs | Description |
|------|---------|-------------|
| **ParcelleStatus** | `ACTIVE`, `EN_REPOS`, `PREPAREE`, `ENSEMENCEE`, `EN_CROISSANCE`, `RECOLTE` | État de la parcelle |
| **ParcelleHealth** | `OPTIMAL`, `SURVEILLANCE`, `CRITIQUE` | Santé de la parcelle |
| **CropCategory** | `CEREALES`, `LEGUMINEUSES`, `TUBERCULES`, `LEGUMES`, `FRUITS`, `OLEAGINEUX` | Catégorie de culture |

### 3.3 Capteurs IoT

| Enum | Valeurs | Description |
|------|---------|-------------|
| **StationStatus** | `ACTIVE`, `MAINTENANCE`, `HORS_SERVICE` | État de la station |
| **CapteurType** | `HUMIDITE_TEMPERATURE_AMBIANTE`, `HUMIDITE_SOL`, `UV`, `NPK`, `DIRECTION_VENT`, `TRANSPIRATION_PLANTE` | Type de capteur |
| **CapteurStatus** | `ACTIF`, `INACTIF`, `MAINTENANCE`, `DEFAILLANT` | État du capteur |

### 3.4 Alertes

| Enum | Valeurs | Description |
|------|---------|-------------|
| **AlertLevel** | `INFO`, `IMPORTANT`, `CRITIQUE` | Niveau d'urgence |
| **AlertStatus** | `NOUVELLE`, `LUE`, `TRAITEE`, `IGNOREE` | État de l'alerte |

### 3.5 Transactions

| Enum | Valeurs | Description |
|------|---------|-------------|
| **OrderStatus** | `PENDING`, `CONFIRMED`, `SHIPPED`, `DELIVERED`, `CANCELLED` | État de commande |
| **TransactionStatus** | `PENDING`, `COMPLETED`, `FAILED`, `REFUNDED` | État de transaction |

---

## 4. Tables - Description Détaillée

### 4.1 Gestion des Utilisateurs

#### **User** (users)

Table centrale des utilisateurs.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `nom` | VARCHAR(100) | Nom de famille |
| `prenoms` | VARCHAR(150) | Prénoms |
| `email` | VARCHAR(150) | Email (unique, optionnel) |
| `telephone` | VARCHAR(20) | Téléphone (unique, requis) |
| `passwordHash` | VARCHAR(255) | Mot de passe hashé (bcrypt) |
| `role` | UserRole | Rôle (défaut: PRODUCTEUR) |
| `status` | UserStatus | Statut du compte |
| `regionId` | UUID | Région de l'utilisateur |
| `photoProfil` | TEXT | URL de la photo |
| `dateNaissance` | DATE | Date de naissance |
| `langue_preferee` | VARCHAR(10) | Langue (défaut: "fr") |
| `production3MoisPrecedentsKg` | DECIMAL | Production déclarée |
| `typeProducteur` | VARCHAR(100) | Type de producteur |
| `superficieExploitee` | DECIMAL | Surface exploitée |
| `systemeIrrigation` | VARCHAR(100) | Système d'irrigation |

**Relations :**

- 1:N → `Parcelle`, `Diagnostic`, `ForumPost`, `MarketplaceProduit`, `Message`, etc.

#### **OtpCode** (otp_codes)

Codes de vérification temporaires.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | ID utilisateur |
| `code` | VARCHAR(10) | Code OTP |
| `type` | OtpType | Type (LOGIN/REGISTER/RESET) |
| `expiresAt` | DATETIME | Date d'expiration |
| `used` | BOOLEAN | Déjà utilisé |

#### **RefreshToken** (refresh_tokens)

Tokens de rafraîchissement JWT.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | ID utilisateur |
| `token` | TEXT | Token JWT |
| `expiresAt` | DATETIME | Expiration |

---

### 4.2 Gestion des Parcelles Agricoles

#### **Parcelle** (parcelles)

Parcelles agricoles des utilisateurs.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Propriétaire |
| `nom` | VARCHAR(200) | Nom de la parcelle |
| `superficie` | DECIMAL(10,2) | Surface en hectares |
| `typeSol` | VARCHAR(50) | Type de sol |
| `latitude` | DECIMAL(10,8) | Coordonnée GPS |
| `longitude` | DECIMAL(11,8) | Coordonnée GPS |
| `cultureActuelle` | VARCHAR(100) | Culture en cours |
| `datePlantation` | DATE | Date de plantation |
| `statut` | ParcelleStatus | État (ACTIVE...) |
| `sante` | ParcelleHealth | Santé (OPTIMAL...) |

**Relations :**

- N:1 → `User`, `Region`
- 1:N → `Station`, `Capteur`, `Diagnostic`, `Plantation`

#### **Plantation** (plantations)

Plantations sur les parcelles.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `parcelleId` | UUID | Parcelle |
| `cultureId` | UUID | Culture plantée |
| `datePlantation` | DATETIME | Date de plantation |
| `dateRecolte` | DATETIME | Date de récolte |
| `quantitePlantee` | DECIMAL | Quantité plantée |

#### **Culture** (cultures)

Catalogue des cultures.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `nom` | VARCHAR(100) | Nom (ex: "Maïs") |
| `nomScientifique` | VARCHAR(150) | Nom latin |
| `categorie` | CropCategory | Catégorie |
| `dureeJours` | INT | Durée du cycle |
| `phOptimal` | DECIMAL | pH optimal |
| `temperatureMin/Max` | DECIMAL | Températures |
| `rendementMoyen` | DECIMAL | Rendement moyen |

---

### 4.3 Capteurs IoT et Mesures

#### **Station** (stations)

Stations météo / IoT sur les parcelles.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `parcelleId` | UUID | Parcelle associée |
| `nom` | VARCHAR(200) | Nom de la station |
| `code` | VARCHAR(100) | Code unique |
| `modele` | VARCHAR(100) | Modèle matériel |
| `numeroSerie` | VARCHAR(100) | Numéro de série |
| `statut` | StationStatus | État |
| `batterie` | INT | Niveau batterie (%) |
| `signal` | INT | Force du signal |

#### **Capteur** (capteurs)

Capteurs individuels.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `stationId` | UUID | Station (optionnel) |
| `parcelleId` | UUID | Parcelle |
| `nom` | VARCHAR(200) | Nom du capteur |
| `type` | CapteurType | Type de mesure |
| `unite` | VARCHAR(20) | Unité (%, °C, etc.) |
| `seuilMin` | DECIMAL | Seuil minimum alerte |
| `seuilMax` | DECIMAL | Seuil maximum alerte |
| `statut` | CapteurStatus | État |

#### **Mesure** (mesures)

Données collectées par les capteurs.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `capteurId` | UUID | Capteur source |
| `valeur` | VARCHAR(50) | Valeur mesurée |
| `unite` | VARCHAR(20) | Unité |
| `timestamp` | DATETIME | Horodatage |

> **Note :** Les mesures haute fréquence sont stockées dans **InfluxDB** pour de meilleures performances.

#### **Alerte** (alertes)

Alertes générées par le système.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur concerné |
| `capteurId` | UUID | Capteur (optionnel) |
| `type` | VARCHAR(50) | Type d'alerte |
| `niveau` | AlertLevel | Niveau (INFO/IMPORTANT/CRITIQUE) |
| `titre` | VARCHAR(255) | Titre |
| `message` | TEXT | Message détaillé |
| `statut` | AlertStatus | État de l'alerte |

---

### 4.4 Diagnostic IA

#### **Diagnostic** (diagnostics)

Résultats d'analyse IA des maladies.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur |
| `parcelleId` | UUID | Parcelle (optionnel) |
| `type` | VARCHAR(50) | Type de diagnostic |
| `diseaseName` | VARCHAR(255) | Maladie détectée |
| `cropType` | VARCHAR(100) | Type de culture |
| `confidenceScore` | DECIMAL(5,2) | Score de confiance (%) |
| `severity` | VARCHAR(50) | Sévérité |
| `imageUrl` | TEXT | URL de l'image analysée |
| `recommendations` | TEXT | Recommandations |
| `treatmentSuggestions` | TEXT | Suggestions de traitement |

#### **Maladie** (maladies)

Catalogue des maladies.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `nom` | VARCHAR(100) | Nom commun |
| `nomScientifique` | VARCHAR(150) | Nom scientifique |
| `type` | VARCHAR(50) | Type (fongique, bactérien...) |
| `symptomes` | TEXT | Symptômes |
| `traitements` | JSON | Traitements possibles |
| `prevention` | JSON | Mesures préventives |
| `culturesAffectees` | JSON | Cultures touchées |

#### **DetectionMaladie** (detections_maladies)

Historique des détections par IA.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur |
| `imageUrl` | TEXT | Image analysée |
| `maladieDetecteeId` | UUID | Maladie identifiée |
| `confiance` | DECIMAL(5,4) | Score de confiance |
| `confirme` | BOOLEAN | Confirmé par expert |
| `maladieCorrigeeId` | UUID | Correction éventuelle |

---

### 4.5 Marketplace

#### **MarketplaceProduit** (marketplace_produits)

Produits en vente.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `vendeurId` | UUID | Vendeur |
| `nom` | VARCHAR(255) | Nom du produit |
| `description` | TEXT | Description |
| `categorie` | VARCHAR(100) | Catégorie |
| `prix` | DECIMAL(12,2) | Prix en FCFA |
| `unite` | VARCHAR(50) | Unité (kg, sac...) |
| `stock` | INT | Quantité disponible |
| `images` | JSON | URLs des images |
| `typeOffre` | VARCHAR(20) | "vente" ou "location" |
| `actif` | BOOLEAN | Est disponible |

#### **MarketplaceCommande** (marketplace_commandes)

Commandes passées.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `acheteurId` | UUID | Acheteur |
| `produitId` | UUID | Produit |
| `quantite` | INT | Quantité commandée |
| `prixUnitaire` | DECIMAL(12,2) | Prix unitaire |
| `prixTotal` | DECIMAL(12,2) | Prix total |
| `statut` | OrderStatus | État (PENDING...) |
| `adresseLivraison` | TEXT | Adresse |

#### **MarketplaceTransaction** (marketplace_transactions)

Paiements des commandes.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `commandeId` | UUID | Commande |
| `montant` | DECIMAL(12,2) | Montant |
| `methodePaiement` | VARCHAR(50) | Mobile Money, etc. |
| `statut` | TransactionStatus | État |
| `referenceTransaction` | VARCHAR(100) | Référence unique |

---

### 4.6 Location d'Équipements

#### **EquipementLocation** (equipements_location)

Équipements disponibles à la location.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `proprietaireId` | UUID | Propriétaire |
| `nom` | VARCHAR(200) | Nom |
| `categorie` | VARCHAR(100) | Catégorie |
| `prixJour` | DECIMAL(10,2) | Prix/jour |
| `caution` | DECIMAL(10,2) | Caution |
| `localisation` | VARCHAR(255) | Localisation |
| `disponible` | BOOLEAN | Disponibilité |

#### **Location** (locations)

Locations en cours.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `equipementId` | UUID | Équipement loué |
| `locataireId` | UUID | Locataire |
| `dateDebut` | DATE | Début location |
| `dateFin` | DATE | Fin location |
| `prixTotal` | DECIMAL(12,2) | Prix total |
| `statut` | VARCHAR(50) | État |

---

### 4.7 Formations

#### **Formation** (formations)

Formations disponibles.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `titre` | VARCHAR(255) | Titre |
| `description` | TEXT | Description |
| `categorie` | VARCHAR(100) | Catégorie |
| `niveau` | VARCHAR(50) | Niveau (débutant...) |
| `dureeMinutes` | INT | Durée totale |
| `vues` | INT | Nombre de vues |
| `active` | BOOLEAN | Est active |

#### **ModuleFormation** (modules_formation)

Modules d'une formation.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `formationId` | UUID | Formation parent |
| `titre` | VARCHAR(255) | Titre du module |
| `contenu` | TEXT | Contenu |
| `ordre` | INT | Ordre d'affichage |
| `videoUrl` | TEXT | URL vidéo |
| `quizData` | JSON | Données du quiz |

#### **ProgressionFormation** (progressions_formation)

Progression des utilisateurs.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur |
| `formationId` | UUID | Formation |
| `progression` | INT | Pourcentage (0-100) |
| `complete` | BOOLEAN | Terminée |
| `score` | INT | Score au quiz |
| `certificatUrl` | TEXT | URL du certificat |

---

### 4.8 Communauté (Forum)

#### **ForumPost** (forum_posts)

Publications du forum.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `auteurId` | UUID | Auteur |
| `titre` | VARCHAR(255) | Titre |
| `contenu` | TEXT | Contenu |
| `categorie` | VARCHAR(100) | Catégorie |
| `vues` | INT | Nombre de vues |
| `resolu` | BOOLEAN | Question résolue |

#### **ForumReponse** (forum_reponses)

Réponses aux posts.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `postId` | UUID | Post parent |
| `auteurId` | UUID | Auteur |
| `contenu` | TEXT | Contenu |
| `estSolution` | BOOLEAN | Marquée comme solution |
| `upvotes` | INT | Votes positifs |

#### **Message** (messages)

Messagerie privée.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `expediteurId` | UUID | Expéditeur |
| `destinataireId` | UUID | Destinataire |
| `sujet` | VARCHAR(255) | Sujet |
| `contenu` | TEXT | Contenu |
| `lu` | BOOLEAN | Message lu |

---

### 4.9 Analytics et Suivi

#### **Economies** (economies)

Suivi des économies réalisées.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur |
| `eauEconomiseePourcentage` | DECIMAL | % eau économisée |
| `engraisEconomisePourcentage` | DECIMAL | % engrais économisé |
| `pertesEviteesPourcentage` | DECIMAL | % pertes évitées |
| `economiesTotalesFcfa` | DECIMAL | Économies en FCFA |

#### **RoiTracking** (roi_tracking)

Suivi du retour sur investissement.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `parcelleId` | UUID | Parcelle |
| `coutSemences` | DECIMAL | Coût semences |
| `coutEngrais` | DECIMAL | Coût engrais |
| `coutMainOeuvre` | DECIMAL | Coût main d'œuvre |
| `quantiteRecoltee` | DECIMAL | Quantité récoltée |
| `prixVenteUnitaire` | DECIMAL | Prix de vente |

#### **PerformanceParcelle** (performance_parcelles)

Performance annuelle par parcelle.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `parcelleId` | UUID | Parcelle |
| `annee` | INT | Année |
| `rendementMoyen` | DECIMAL | Rendement moyen |
| `scoreQualiteSol` | DECIMAL | Score qualité sol |

---

### 4.10 Gamification

#### **Badge** (badges)

Badges disponibles.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `nom` | VARCHAR(100) | Nom du badge |
| `description` | TEXT | Description |
| `icone` | VARCHAR(255) | Icône |
| `condition` | JSON | Conditions d'obtention |
| `points` | INT | Points accordés |

#### **UserBadge** (user_badges)

Badges obtenus par les utilisateurs.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur |
| `badgeId` | UUID | Badge |
| `obtenuLe` | DATETIME | Date d'obtention |

---

### 4.11 Logs et Audit

#### **ActivitiesLog** (activities_log)

Journal des activités utilisateur.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur |
| `action` | VARCHAR(100) | Action effectuée |
| `description` | TEXT | Description |
| `ipAddress` | VARCHAR(45) | Adresse IP |
| `userAgent` | TEXT | User Agent |

#### **AuditLog** (audit_logs)

Audit des modifications de données.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | UUID | Identifiant unique |
| `tableName` | VARCHAR(100) | Table modifiée |
| `recordId` | VARCHAR | ID de l'enregistrement |
| `action` | VARCHAR(20) | CREATE/UPDATE/DELETE |
| `oldData` | JSON | Anciennes données |
| `newData` | JSON | Nouvelles données |
| `userId` | UUID | Utilisateur responsable |

---

## 5. Index et Performances

### 5.1 Index Principaux

| Table | Index | Colonnes |
|-------|-------|----------|
| users | email_idx | email |
| users | telephone_idx | telephone |
| parcelles | user_id_idx | user_id |
| mesures | capteur_timestamp_idx | capteur_id, timestamp |
| alertes | user_statut_idx | user_id, statut |

### 5.2 Contraintes de Clés

- **Clés primaires** : UUID générés automatiquement
- **Clés étrangères** : Cascade sur DELETE pour la plupart
- **Contraintes UNIQUE** : email, telephone, code, etc.

---

## 6. Commandes Prisma Utiles

```bash
# Générer le client Prisma
npx prisma generate

# Appliquer les migrations
npx prisma migrate dev

# Créer une migration
npx prisma migrate dev --name nom_migration

# Ouvrir Prisma Studio (interface graphique)
npx prisma studio

# Synchroniser le schéma sans migration
npx prisma db push

# Réinitialiser la base (⚠️ perd les données)
npx prisma migrate reset

# Voir l'état des migrations
npx prisma migrate status

# Générer le schéma SQL
npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma
```

---

## 7. Sécurité des Données

### 7.1 Données Sensibles

| Donnée | Protection |
|--------|-----------|
| Mots de passe | Hashage bcrypt (10 rounds) |
| Tokens JWT | Stockage en base, expiration |
| Codes OTP | Expiration courte (5 min) |
| Données personnelles | Conformité RGPD |

### 7.2 Sauvegardes

- **Fréquence** : Quotidienne
- **Rétention** : 30 jours
- **Type** : Dump MySQL complet

---

## 8. Résumé des Relations

```
User (1) ─────── (N) Parcelle
Parcelle (1) ─── (N) Station
Station (1) ──── (N) Capteur
Capteur (1) ──── (N) Mesure
User (1) ─────── (N) Diagnostic
User (1) ─────── (N) MarketplaceProduit
User (1) ─────── (N) MarketplaceCommande
User (1) ─────── (N) ProgressionFormation
User (1) ─────── (N) ForumPost
User (1) ─────── (N) Message
Formation (1) ── (N) ModuleFormation
Parcelle (1) ─── (N) Plantation
Culture (1) ──── (N) Plantation
```

---

> Documentation générée pour la présentation du projet Agrosmart CI
