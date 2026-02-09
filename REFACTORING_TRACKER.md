# AgroSmart - Plan de Refactoring & Suivi

> **Date de début** : 8 février 2026
> **Objectif** : Nettoyer l'application, éliminer toute duplication/redondance, stabiliser l'architecture

---

## Progression Globale

| # | Tâche | Priorité | Statut |
|---|-------|----------|--------|
| 1 | Nettoyer tous les `console.log` de debug du backend | CRITIQUE | ✅ Terminé |
| 2 | Fixer le double montage de routes dans `server.js` | CRITIQUE | ✅ Terminé |
| 3 | Réactiver le code désactivé (stocks, calendrier, reviews, wishlist) | CRITIQUE | ✅ Terminé |
| 4 | Nettoyer code mort + remplacer `console.error` par `logger.error` | HAUTE | ✅ Terminé |
| 5 | Extraire le routing du `main.dart` mobile | HAUTE | ✅ Terminé |
| 6 | Extraire les BLoC providers dans un fichier dédié | HAUTE | ✅ Terminé |
| 7 | Extraire la configuration des thèmes mobile | HAUTE | ✅ Terminé |
| 8 | Centraliser et sécuriser le stockage des tokens frontend | HAUTE | ✅ Terminé |
| 9 | Ajouter validation et logging structuré au service IA | HAUTE | ✅ Terminé |
| 10 | Mettre à jour l'architecture finale | FIN | ✅ Terminé |

---

## Détail des changements

### 1. Nettoyer les console.log de debug ✅
**Fichiers modifiés** :
- `backend/src/server.js` — Supprimé tous les `console.log('🔵 ...')`
- `backend/src/routes/index.js` — Supprimé tous les `console.log` de chargement de routes
- `backend/src/middlewares/errorHandler.js` — `console.error` → `logger.error`
- `backend/src/middlewares/validation.js` — `console.log` → `logger.debug`, ajout import logger
- `backend/src/controllers/capteursController.js` — Supprimé 2 `console.log` DEBUG
- `backend/src/config/database.js` — `console.log` → `logger.debug`
- `backend/src/config/swagger.js` — `console.log` → `logger.info`

---

### 2. Fixer le double montage de routes ✅
**Fichier** : `backend/src/server.js`

**Problème** : Les routes étaient montées via `routes/index.js` sur `/api/v1` ET ré-importées individuellement (`/api/parcelles`, `/api/alertes`, etc.) = routes dupliquées.

**Solution** : Supprimé les 7 imports individuels et les 7 `app.use('/api/...')`. Ne reste qu'un seul `app.use('/api/v1', routes)`.

---

### 3. Réactiver le code désactivé ✅
**Fichiers modifiés** :
- `backend/src/routes/stocks.js` — Import corrigé : `../middlewares/validate` → `../middlewares/validation`
- `backend/src/routes/calendrier.js` — Import corrigé : `../middlewares/validate` → `../middlewares/validation`
- `backend/src/routes/reviews.js` — **Réécrit entièrement** : correction noms de champs Prisma (snake_case → camelCase), utilisation client Prisma partagé, middleware `authenticate`, logger
- `backend/src/routes/wishlist.js` — **Réécrit entièrement** : mêmes corrections, modèle `marketplaceProduit` au lieu de `produit`, champs corrects
- `backend/src/routes/index.js` — Les 34 routes toutes activées proprement

---

### 4. Nettoyer code mort + console.error → logger.error ✅
**Fichiers modifiés (9 controllers)** :
- `backend/src/controllers/chatController.js`
- `backend/src/controllers/equipmentController.js`
- `backend/src/controllers/gamificationController.js`
- `backend/src/controllers/analyticsController.js`
- `backend/src/controllers/diagnosticsController.js`
- `backend/src/controllers/paymentController.js`
- `backend/src/controllers/groupPurchasesController.js`
- `backend/src/controllers/weatherController.js`

**Changements** : Ajout `const logger = require('../utils/logger')`, remplacement de tous les `console.error()` par `logger.error()`.

**Fichier** : `backend/src/services/passwordService.js` — Remplacé `new PrismaClient()` par client partagé, `console.error` → `logger.error`.

---

### 5. Extraire le routing mobile ✅
**Avant** : `mobile/lib/main.dart` — 490 lignes, ~60 imports, ~40 routes GoRouter inline
**Après** : **83 lignes** dans `main.dart`

**Nouveau fichier** : `mobile/lib/core/router/app_router.dart`
- Classe `AppRouter` avec `static final GoRouter router`
- ~40 routes organisées par catégorie (Auth, Commerce, Dashboard, Diagnostics, Marketplace, Communication, Outils, Profil)
- Tous les imports de pages déplacés dans ce fichier

---

### 6. Extraire les BLoC providers ✅
**Nouveau fichier** : `mobile/lib/core/providers/app_providers.dart`
- Classe `AppProviders` avec `static List<BlocProvider> get providers`
- 16 BlocProviders (Auth, Theme, Settings, Parcelle, Sensor, Alert, Weather, Marketplace, Analytics, Recommandation, Equipment, Chat, CommunityListing, Chatbot, Cart, Favorites)
- Tous les imports de blocs déplacés dans ce fichier

---

### 7. Extraire la configuration des thèmes ✅
**Nouveau fichier** : `mobile/lib/core/theme/app_theme.dart`
- Classe `AppTheme` avec `static ThemeData get light` et `static ThemeData get dark`
- Thème Material3 complet (couleurs, cards, inputs, boutons, textes, dark mode)

---

### 8. Centraliser le stockage des tokens ✅
**Fichiers modifiés** :
- `frontend/src/lib/api.ts` — Ajout fonctions `getPersistedToken()` et `clearPersistedAuth()` qui lisent le token depuis le store Zustand persisté (`auth-storage`) au lieu de `localStorage.getItem('token')`. Supprimé les accès directs `localStorage.removeItem('token')` et `localStorage.removeItem('user')`.
- `frontend/src/lib/store.ts` — Simplifié `login()` : plus de `localStorage.setItem('token')` redondant (Zustand persist s'en charge). Simplifié `logout()` : ne supprime que `auth-storage`.
- `frontend/src/app/(dashboard)/layout.tsx` — Supprimé `localStorage.getItem('token')`, utilise uniquement `token` du store.
- `frontend/src/app/(admin)/layout.tsx` — Idem.
- `frontend/src/app/(dashboard)/settings/page.tsx` — Import `useAuthStore`, utilise `logout()` du store au lieu d'accès directs localStorage.

**Avantage** : Le token est géré en un seul point. Migration future vers HttpOnly cookies = modifier uniquement `api.ts`.

---

### 9. Validation et logging service IA ✅
**Fichier** : `ai_service/app.py`

**Améliorations** :
- **Logging structuré** : Remplacement de tous les `print()` par `logging.getLogger('ai_service')` avec format horodaté
- **Validation des images** : Vérification extension (png/jpg/jpeg/webp), taille max (10 MB), nom de fichier non vide
- **Validation irrigation** : Fonction `validate_irrigation_input()` — vérification type + plage pour temperature (-50/+70), humidity (0-100), soil_moisture (0-100), crop_type (entier positif)
- **Healthcheck amélioré** : Retourne le statut de chaque modèle (loaded / mock)
- **Erreurs spécifiques** : Distinction `IOError` (image corrompue) vs erreur interne, pas d'exposition d'exceptions brutes
- **Suppression import inutilisé** : `import io` retiré

---

### 10. Architecture finale ✅

```
agriculture/
├── backend/                          # API Node.js Express 5
│   └── src/
│       ├── server.js                 # Point d'entrée (clean, single route mount)
│       ├── config/                   # database, prisma, redis, swagger
│       ├── controllers/              # Logique métier (logger partout)
│       ├── middlewares/              # auth, validation, errorHandler, rbac
│       ├── routes/
│       │   ├── index.js              # Agrégateur central (34 routes)
│       │   ├── stocks.js             # ✅ Réactivé (import corrigé)
│       │   ├── calendrier.js         # ✅ Réactivé (import corrigé)
│       │   ├── reviews.js            # ✅ Réécrit (Prisma correct)
│       │   └── wishlist.js           # ✅ Réécrit (Prisma correct)
│       ├── services/                 # passwordService (shared prisma)
│       ├── utils/                    # logger (Winston)
│       └── workers/                  # BullMQ workers
│
├── frontend/                         # Next.js 16 / React 19
│   └── src/
│       ├── lib/
│       │   ├── api.ts                # ✅ Token centralisé via Zustand persist
│       │   └── store.ts             # ✅ Login/logout simplifiés
│       ├── app/
│       │   ├── (dashboard)/layout.tsx # ✅ Auth via store (pas localStorage)
│       │   ├── (admin)/layout.tsx     # ✅ Idem
│       │   └── (dashboard)/settings/  # ✅ Logout via store
│       └── components/
│
├── mobile/                           # Flutter (Clean Architecture + BLoC)
│   └── lib/
│       ├── main.dart                 # ✅ 83 lignes (était 490)
│       ├── core/
│       │   ├── router/
│       │   │   └── app_router.dart   # ✅ NOUVEAU — 40 routes GoRouter
│       │   ├── providers/
│       │   │   └── app_providers.dart # ✅ NOUVEAU — 16 BlocProviders
│       │   └── theme/
│       │       ├── theme_cubit.dart   # (existant)
│       │       └── app_theme.dart     # ✅ NOUVEAU — Light + Dark themes
│       ├── features/                  # Feature-based architecture
│       └── injection_container.dart   # GetIt DI
│
├── ai_service/                       # Python Flask + TensorFlow
│   └── app.py                        # ✅ Validation, logging structuré, erreurs propres
│
├── iot_service/                      # Node.js + MQTT + BullMQ
│   └── index.js
│
├── docker-compose.yml                # Dev environment
├── docker-compose.prod.yml           # Production
└── nginx/                            # Reverse proxy
```

---

## Journal des modifications

| Date | Tâche | Fichiers modifiés | Notes |
|------|-------|-------------------|-------|
| 08/02/2026 | #1 Clean console.log | server.js, routes/index.js, errorHandler, validation, capteurs, database, swagger | Tout remplacé par logger |
| 08/02/2026 | #2 Fix double routes | server.js | Supprimé 7 imports + 7 app.use individuels |
| 08/02/2026 | #3 Fix disabled routes | stocks.js, calendrier.js, reviews.js, wishlist.js, routes/index.js | Imports corrigés, reviews/wishlist réécrits |
| 08/02/2026 | #4 Clean console.error | 9 controllers + passwordService | logger.error partout, shared Prisma client |
| 08/02/2026 | #5 Extract mobile router | main.dart, NEW app_router.dart | 490→83 lignes |
| 08/02/2026 | #6 Extract BLoC providers | main.dart, NEW app_providers.dart | 16 providers extraits |
| 08/02/2026 | #7 Extract theme config | main.dart, NEW app_theme.dart | Light + Dark themes |
| 08/02/2026 | #8 Centralize token | api.ts, store.ts, dashboard/layout, admin/layout, settings | Plus de localStorage direct pour tokens |
| 08/02/2026 | #9 AI validation | ai_service/app.py | Validation images/inputs, logging structuré |
| 08/02/2026 | #11 Fix Prisma models | schema.prisma, chatController.js, gamificationController.js | Ajout UserPoint, Conversation models, fix MySQL JSON queries |

---

## Vérification Complète des Fonctionnalités

### Services Docker (10/10)
| Service | Port | Status |
|---------|------|--------|
| agrismart_api | 3000 | ✅ Healthy |
| agrismart_frontend | 3001→3000 | ✅ Healthy |
| agrismart_ai | 5001 | ✅ Healthy |
| agrismart_iot | 4000 | ✅ Healthy (MQTT + Redis connected) |
| agrismart_mysql | 3306 | ✅ Healthy |
| agrismart_redis | 6379 | ✅ Healthy |
| agrismart_influxdb | 8086 | ✅ Running |
| agrismart_mosquitto | 1883/9001 | ✅ Running |
| agrismart_nginx | 80/443 | ✅ Running |
| agrismart_phpmyadmin | 8080 | ✅ Running |

### Authentification
| Test | Status |
|------|--------|
| POST /auth/register | ✅ 201 - Création utilisateur |
| POST /auth/login | ✅ 200 - Retourne accessToken + refreshToken |
| Token JWT validation | ✅ Fonctionne sur routes protégées |
| 401 sans token | ✅ Rejeté correctement |

### Endpoints API GET (tous 200)
| Route | Status | Données |
|-------|--------|---------|
| GET /health | ✅ 200 | Status, uptime, memory |
| GET /parcelles | ✅ 200 | Liste des parcelles |
| GET /capteurs | ✅ 200 | Liste des capteurs |
| GET /mesures | ✅ 200 | Mesures IoT |
| GET /alertes | ✅ 200 | Alertes actives |
| GET /cultures | ✅ 200 | Cultures disponibles |
| GET /maladies | ✅ 200 | Maladies référencées |
| GET /recommandations | ✅ 200 | Recommandations agricoles |
| GET /marketplace/produits | ✅ 200 | Produits marketplace |
| GET /formations | ✅ 200 | Formations disponibles |
| GET /messages/conversations | ✅ 200 | Conversations utilisateur |
| GET /analytics/stats | ✅ 200 | Statistiques globales |
| GET /cart | ✅ 200 | Panier utilisateur |
| GET /favorites | ✅ 200 | Favoris utilisateur |
| GET /stocks | ✅ 200 | Stocks utilisateur |
| GET /calendrier | ✅ 200 | Activités calendrier |
| GET /wishlist | ✅ 200 | Liste de souhaits |
| GET /users/profile | ✅ 200 | Profil utilisateur |
| GET /regions | ✅ 200 | Régions Côte d'Ivoire |
| GET /dashboard/stats | ✅ 200 | Stats dashboard |
| GET /communaute/posts | ✅ 200 | Posts communauté |
| GET /gamification/points | ✅ 200 | Points utilisateur |
| GET /gamification/leaderboard | ✅ 200 | Classement |
| GET /gamification/badges | ✅ 200 | Badges utilisateur |
| GET /diagnostics/history | ✅ 200 | Historique diagnostics |
| GET /chat/conversations | ✅ 200 | Conversations chat |
| GET /chatbot/actions | ✅ 200 | Actions disponibles (public) |
| GET /chatbot/languages | ✅ 200 | Langues supportées |
| GET /weather/current | ✅ 200 | Météo actuelle |
| GET /payments/transactions | ✅ 200 | Transactions paiement |
| GET /group-purchases/ | ✅ 200 | Achats groupés |

### Endpoints API POST (écriture)
| Route | Status | Notes |
|-------|--------|-------|
| POST /parcelles | ✅ 201 | Création parcelle |
| POST /marketplace/produits | ✅ 201 | Création produit |
| POST /stocks | ✅ 201 | Création stock |
| POST /calendrier | ✅ 201 | Création activité |
| POST /wishlist | ✅ 201 | Ajout wishlist |
| POST /cart/items | ✅ 201 | Ajout panier |
| POST /favorites | ✅ 201 | Ajout favoris |
| POST /gamification/points/award | ✅ 200 | Attribution points |

### Validation
| Test | Status |
|------|--------|
| Champs manquants | ✅ 422 avec messages clairs |
| Catégories invalides | ✅ 422 rejeté proprement |

### Frontend Web
| Test | Status |
|------|--------|
| Page d'accueil (/) | ✅ 200 |
| Page login (/login) | ✅ 200 - Formulaire telephone/password |
| Page register (/register) | ✅ 200 |
| Dashboard (/dashboard) | ✅ 200 |
| Marketplace (/marketplace) | ✅ 200 |
| Parcelles (/parcelles) | ✅ 200 |
| Formations (/formations) | ✅ 200 |
| API URL configurée | ✅ http://localhost:3000/api/v1 |
| Token Zustand persist | ✅ localStorage auth-storage |
| Intercepteur Axios | ✅ Bearer token auto-injecté |
| Gestion 401 | ✅ Redirect vers /login |
| Aucune erreur dans les logs | ✅ |

### Services Externes
| Service | Status |
|---------|--------|
| AI Service (/health) | ✅ 200 - healthy |
| IoT Service (/health) | ✅ 200 - MQTT + Redis connected |

### Corrections appliquées pendant vérification
| Problème | Solution |
|----------|----------|
| `calendrier_activites` table manquante | Ajout modèle + `prisma db push` |
| Migration `20240115_add_wishlist_and_reviews` pending | `prisma migrate deploy` |
| `prisma.userPoint` undefined (gamification 500) | Ajout modèle `UserPoint` au schema |
| `prisma.conversation` undefined (chat 500) | Ajout modèle `Conversation` au schema |
| `participants: { has: userId }` incompatible MySQL | Remplacement par `$queryRaw` JSON_CONTAINS |
| `dateObtention` field inexistant dans UserBadge | Corrigé en `obtenuLe` |
| `luAt` field inexistant dans Message | Supprimé de la mise à jour |
