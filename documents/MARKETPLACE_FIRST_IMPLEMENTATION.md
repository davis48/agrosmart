# 🛒 Plan d'Implémentation : Workflow Marketplace-First

## 📋 Résumé des Changements

### Objectif
Transformer AgriSmart CI en une application **marketplace-first** (style Jumia) avec deux types d'utilisateurs distincts :
- **Acheteur** : Accès simplifié, peut naviguer sans compte, dashboard acheteur
- **Producteur** : Parcours complet avec infos production, dashboard producteur (existant)

---

## 🔄 Nouveau Workflow Utilisateur

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        NOUVEAU FLUX UTILISATEUR                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐      ┌─────────────────┐      ┌─────────────────┐          │
│  │  Splash     │ ───► │   MARKETPLACE   │ ◄─── │  Navigation     │          │
│  │  Screen     │      │   (Accueil)     │      │  Libre          │          │
│  └─────────────┘      └────────┬────────┘      └─────────────────┘          │
│                                │                                             │
│                    ┌───────────┼───────────┐                                │
│                    │           │           │                                 │
│                    ▼           ▼           ▼                                 │
│              ┌──────────┐ ┌──────────┐ ┌──────────┐                         │
│              │ Parcourir│ │ Ajouter  │ │ Valider  │                         │
│              │ Produits │ │ Panier   │ │ Achat    │                         │
│              │ (LIBRE)  │ │ (LIBRE)  │ │ (AUTH)   │                         │
│              └──────────┘ └──────────┘ └────┬─────┘                         │
│                                             │                                │
│                           ┌─────────────────┴─────────────────┐             │
│                           │      AUTHENTIFICATION REQUISE     │             │
│                           └─────────────────┬─────────────────┘             │
│                                             │                                │
│                    ┌────────────────────────┼────────────────────────┐      │
│                    │                        │                        │       │
│                    ▼                        ▼                        ▼       │
│              ┌──────────┐           ┌──────────┐             ┌──────────┐   │
│              │  Login   │           │ Register │             │  Guest   │   │
│              │          │           │          │             │ Checkout │   │
│              └────┬─────┘           └────┬─────┘             │ (Future) │   │
│                   │                      │                   └──────────┘   │
│                   │                      │                                   │
│                   │              ┌───────┴───────┐                           │
│                   │              │  CHOIX RÔLE   │                           │
│                   │              └───────┬───────┘                           │
│                   │                      │                                   │
│                   │         ┌────────────┴────────────┐                     │
│                   │         │                         │                      │
│                   │         ▼                         ▼                      │
│                   │   ┌──────────┐             ┌──────────┐                 │
│                   │   │ ACHETEUR │             │PRODUCTEUR│                 │
│                   │   │ (Simple) │             │(Complet) │                 │
│                   │   └────┬─────┘             └────┬─────┘                 │
│                   │        │                        │                        │
│                   │        │                   ┌────┴────┐                   │
│                   │        │                   │ Step 2: │                   │
│                   │        │                   │ Produc. │                   │
│                   │        │                   └────┬────┘                   │
│                   │        │                        │                        │
│                   │        │                   ┌────┴────┐                   │
│                   │        │                   │ Step 3: │                   │
│                   │        │                   │ Histo.  │                   │
│                   │        │                   └────┬────┘                   │
│                   │        │                        │                        │
│                   ▼        ▼                        ▼                        │
│              ┌──────────────────────────────────────────────┐               │
│              │              DASHBOARDS                       │               │
│              ├──────────────────┬───────────────────────────┤               │
│              │  ACHETEUR        │  PRODUCTEUR               │               │
│              │  - Mes commandes │  - Parcelles              │               │
│              │  - Favoris       │  - Capteurs               │               │
│              │  - Historique    │  - Diagnostics            │               │
│              │  - Suivi livr.   │  - Météo                  │               │
│              │  - Marketplace   │  - Marketplace            │               │
│              └──────────────────┴───────────────────────────┘               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📱 PHASE 1 : MOBILE (Priorité Haute)

### 1.1 Navigation - Marketplace First
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| NAV-01 | Changer `initialLocation` de `/onboarding` vers `/marketplace` | `main.dart` | ⬜ À faire |
| NAV-02 | Créer shell route avec bottom navigation (Marketplace, Panier, Profil) | `main.dart` | ⬜ À faire |
| NAV-03 | Ajouter route `/home` qui redirige selon le rôle (dashboard acheteur/producteur) | `main.dart` | ⬜ À faire |
| NAV-04 | Adapter onboarding comme optionnel (bouton "Passer") | `onboarding_page.dart` | ⬜ À faire |

### 1.2 Authentification Optionnelle
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| AUTH-01 | Créer `AuthGuard` widget pour protéger actions sensibles | `core/widgets/auth_guard.dart` | ⬜ À faire |
| AUTH-02 | Modifier panier pour stocker localement avant auth | `cart_bloc.dart` | ⬜ À faire |
| AUTH-03 | Ajouter état `AuthState.guest` dans AuthBloc | `auth_bloc.dart` | ⬜ À faire |
| AUTH-04 | Créer popup "Connexion requise" réutilisable | `core/widgets/login_required_dialog.dart` | ⬜ À faire |

### 1.3 Inscription avec Choix de Rôle
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| REG-01 | Créer page de sélection de rôle (Acheteur/Producteur) | `role_selection_page.dart` | ⬜ À faire |
| REG-02 | Simplifier RegisterPage pour mode Acheteur (Step 1 seulement) | `register_page.dart` | ⬜ À faire |
| REG-03 | Conserver flow complet pour Producteur (3 steps) | `register_page.dart` | ⬜ À faire |
| REG-04 | Ajouter paramètre `role` à RegisterRequested event | `auth_bloc.dart` | ⬜ À faire |

### 1.4 Dashboard Acheteur (Nouveau)
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| DASH-01 | Créer feature `buyer_dashboard` | `features/buyer_dashboard/` | ⬜ À faire |
| DASH-02 | Page principale avec sections (Commandes, Favoris, etc.) | `buyer_dashboard_page.dart` | ⬜ À faire |
| DASH-03 | Widget "Mes Commandes" récent | `buyer_orders_widget.dart` | ⬜ À faire |
| DASH-04 | Widget "Produits Favoris" | `buyer_favorites_widget.dart` | ⬜ À faire |
| DASH-05 | Widget "Suivi de Livraison" | `buyer_tracking_widget.dart` | ⬜ À faire |
| DASH-06 | BLoC pour le dashboard acheteur | `buyer_dashboard_bloc.dart` | ⬜ À faire |

### 1.5 Panier Amélioré
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| CART-01 | Créer feature `cart` complète | `features/cart/` | ⬜ À faire |
| CART-02 | CartBloc avec persistance locale (Isar) | `cart_bloc.dart` | ⬜ À faire |
| CART-03 | Page panier avec liste produits | `cart_page.dart` | ⬜ À faire |
| CART-04 | Page checkout avec auth guard | `checkout_page.dart` | ⬜ À faire |
| CART-05 | Icône panier dans AppBar avec badge count | `cart_icon_widget.dart` | ⬜ À faire |

### 1.6 Marketplace Amélioré
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| MKT-01 | Ajouter bouton "Ajouter au panier" sur ProductCard | `marketplace_page.dart` | ⬜ À faire |
| MKT-02 | Améliorer ProductDetailPage avec quantité + panier | `product_detail_page.dart` | ⬜ À faire |
| MKT-03 | Ajouter section "Produits Recommandés" | `marketplace_page.dart` | ⬜ À faire |
| MKT-04 | Ajouter filtres par catégorie améliorés | `marketplace_page.dart` | ⬜ À faire |

---

## 🖥️ PHASE 2 : BACKEND

### 2.1 Enum et Schéma
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| DB-01 | Ajouter `ACHETEUR` dans enum `UserRole` | `schema.prisma` | ⬜ À faire |
| DB-02 | Créer table `Cart` (panier persistant) | `schema.prisma` | ⬜ À faire |
| DB-03 | Créer table `CartItem` | `schema.prisma` | ⬜ À faire |
| DB-04 | Créer table `Favorite` (produits favoris) | `schema.prisma` | ⬜ À faire |
| DB-05 | Créer migration Prisma | `prisma/migrations/` | ⬜ À faire |

### 2.2 Endpoints API
| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| API-01 | `POST /api/v1/cart` - Ajouter au panier | `cartController.js` | ⬜ À faire |
| API-02 | `GET /api/v1/cart` - Obtenir le panier | `cartController.js` | ⬜ À faire |
| API-03 | `DELETE /api/v1/cart/:itemId` - Retirer du panier | `cartController.js` | ⬜ À faire |
| API-04 | `POST /api/v1/favorites` - Ajouter aux favoris | `favoritesController.js` | ⬜ À faire |
| API-05 | `GET /api/v1/favorites` - Liste des favoris | `favoritesController.js` | ⬜ À faire |
| API-06 | Modifier `/api/v1/auth/register` pour accepter rôle ACHETEUR | `authController.js` | ⬜ À faire |

---

## 📊 PHASE 3 : TESTS

| # | Tâche | Fichier(s) | Statut |
|---|-------|------------|--------|
| TST-01 | Tests unitaires CartBloc | `cart_bloc_test.dart` | ⬜ À faire |
| TST-02 | Tests BuyerDashboardBloc | `buyer_dashboard_bloc_test.dart` | ⬜ À faire |
| TST-03 | Tests widget AuthGuard | `auth_guard_test.dart` | ⬜ À faire |
| TST-04 | Tests intégration flow achat | `purchase_flow_test.dart` | ⬜ À faire |

---

## 📁 Nouvelles Structures de Fichiers

### Mobile
```
lib/
├── core/
│   └── widgets/
│       ├── auth_guard.dart              # NEW
│       ├── login_required_dialog.dart   # NEW
│       └── cart_icon_widget.dart        # NEW
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── pages/
│   │           └── role_selection_page.dart  # NEW
│   │
│   ├── cart/                            # NEW FEATURE
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── cart_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── cart_item_model.dart
│   │   │   └── repositories/
│   │   │       └── cart_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── cart_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── cart_repository.dart
│   │   │   └── usecases/
│   │   │       ├── add_to_cart.dart
│   │   │       └── get_cart.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── cart_bloc.dart
│   │       ├── pages/
│   │       │   ├── cart_page.dart
│   │       │   └── checkout_page.dart
│   │       └── widgets/
│   │           └── cart_item_widget.dart
│   │
│   └── buyer_dashboard/                 # NEW FEATURE
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── bloc/
│           │   └── buyer_dashboard_bloc.dart
│           ├── pages/
│           │   └── buyer_dashboard_page.dart
│           └── widgets/
│               ├── buyer_orders_widget.dart
│               ├── buyer_favorites_widget.dart
│               └── buyer_tracking_widget.dart
```

### Backend
```
src/
├── controllers/
│   ├── cartController.js      # NEW
│   └── favoritesController.js # NEW
├── routes/
│   ├── cart.js                # NEW
│   └── favorites.js           # NEW
└── services/
    └── cartService.js         # NEW
```

---

## ⏱️ Estimation Temps

| Phase | Durée estimée |
|-------|---------------|
| Phase 1.1 (Navigation) | 1h |
| Phase 1.2 (Auth Guard) | 1h |
| Phase 1.3 (Inscription) | 2h |
| Phase 1.4 (Dashboard Acheteur) | 3h |
| Phase 1.5 (Panier) | 2h |
| Phase 1.6 (Marketplace) | 1h |
| Phase 2 (Backend) | 2h |
| Phase 3 (Tests) | 1h |
| **TOTAL** | **~13h** |

---

## 🚀 Ordre d'Implémentation

1. **Backend** - DB schema + endpoints (base nécessaire)
2. **Mobile Navigation** - Marketplace first
3. **Auth Guard & Widgets** - Composants réutilisables
4. **Panier** - Feature complète
5. **Inscription avec rôles** - Différenciation users
6. **Dashboard Acheteur** - Nouvelle page
7. **Tests** - Validation

---

## ✅ Critères d'Acceptation

- [ ] L'app démarre sur le Marketplace (pas onboarding)
- [ ] Un utilisateur peut parcourir les produits sans compte
- [ ] Un utilisateur peut ajouter au panier sans compte
- [ ] À l'achat, une popup demande la connexion/inscription
- [ ] À l'inscription, l'utilisateur choisit Acheteur ou Producteur
- [ ] L'acheteur a un parcours simplifié (1 étape)
- [ ] Le producteur garde le parcours complet (3 étapes)
- [ ] L'acheteur accède à un dashboard dédié
- [ ] Le producteur accède au dashboard existant

---

> **Date de création** : 29 janvier 2026  
> **Statut** : En cours d'implémentation
