# Politique de Sécurité - AgriSmart CI

## 🔒 Aperçu de la Sécurité

AgriSmart CI implémente un système de sécurité multi-couches conforme aux standards internationaux (OWASP Top 10, ISO 27001). Ce document détaille notre architecture de sécurité, les processus de signalement de vulnérabilités, et les bonnes pratiques pour les contributeurs.

### 6. Protection CORS

#### Configuration Dynamique

```javascript
// Développement: Toutes origines autorisées (*)
// Production: Whitelist stricte via ALLOWED_ORIGINS

// .env.production
ALLOWED_ORIGINS=https://agrismart-ci.com,https://www.agrismart-ci.com,https://admin.agrismart-ci.com
```

**Fonctionnalités**:

- Whitelist dynamique selon environnement
- Validation de l'origine avant traitement
- Logging des tentatives d'accès non autorisées
- Support des requêtes sans origine (mobile apps)

#### Configuration

Via `server.js`:

- Développement : `origin: '*'` (facilite le développement)
- Production : Parse `ALLOWED_ORIGINS` et vérifie chaque requête

### 7. Protection SSRF (Server-Side Request Forgery)

#### Validation des URLs Externes

Nouveau validateur `urlValidation()` dans `commonValidators.js`:

```javascript
const { urlValidation } = require('./validators/commonValidators');

// Whitelist des domaines API autorisés
router.post('/webhook', [
  urlValidation('callbackUrl', 'body', true)
], handler);
```

**Protection**:

- ✅ Whitelist stricte des domaines API (météo, géocodage)
- ✅ Blocage IPs privées (127.0.0.1, 10.x, 192.168.x, etc.)
- ✅ Blocage localhost et 0.0.0.0
- ✅ HTTPS obligatoire en production
- ✅ Validation protocole (http/https uniquement)

**Domaines autorisés**:

- `api.open-meteo.com` (météo)
- `nominatim.openstreetmap.org` (géocodage)
- `overpass-api.de` (OpenStreetMap)
- `api.openweathermap.org` (météo alternative)

### 8. Audit Automatique des Dépendances

#### Script npm-audit.js

Audit automatisé des vulnérabilités npm avec rapports détaillés:

```bash
# Exécution manuelle
npm run audit:security

# Vérification rapide
npm run audit:deps
```

**Fonctionnalités**:

- Génération rapports JSON horodatés
- Tri par sévérité (critical, high, moderate, low)
- Recommandations automatiques
- Exit codes pour CI/CD
- Sauvegarde historique

### 1. Authentification & Autorisation

#### JWT (JSON Web Tokens)

- **Algorithme** : HS256 (HMAC with SHA-256)
- **Expiration tokens** : 24 heures (access), 7 jours (refresh)
- **Stockage** : Refresh tokens en base de données avec possibilité de révocation
- **Rotation** : Les refresh tokens sont révoqués après utilisation

#### Hashage des Mots de Passe

- **Algorithme** : bcrypt avec salt rounds = 10
- **Politique** : Minimum 6 caractères, au moins 1 majuscule
- **Rotation** : Les mots de passe ne sont jamais stockés en clair

#### Contrôle d'Accès (RBAC)

- **Rôles** : PRODUCTEUR, CONSEILLER, ADMIN, PARTENAIRE
- **Permissions** : Granulaires par ressource et action
- **Vérification** : Middleware `rbac.js` sur toutes les routes protégées

### 2. Protection contre les Injections

#### SQL Injection

- **ORM** : Prisma avec requêtes paramétrées (100% des requêtes)
- **Validation** : Express-validator sur tous les endpoints
- **Tests** : Suite automatisée dans `tests/security.test.js`

#### NoSQL Injection

- **Sanitization** : Suppression des caractères spéciaux `$`, `{`, `}`
- **Validation** : Whitelist des champs autorités

#### XSS (Cross-Site Scripting)

- **Sanitization** : Suppression des balises HTML et scripts
- **Headers** : Content Security Policy (CSP) via Helmet.js
- **Encoding** : Échappement automatique des sorties JSON

### 3. Rate Limiting & Protection Brute Force

#### Limites Globales

```javascript
Limite API : 100 requêtes / 15 minutes
Endpoints auth : 10 tentatives / 15 minutes
```

#### Détection d'Anomalies

- Logging des tentatives échouées
- Blocage automatique après seuil dépassé
- Monitoring en temps réel via Winston

### 4. Headers de Sécurité HTTP

Via **Helmet.js**, nous configurons :

- `X-Frame-Options`: DENY
- `X-Content-Type-Options`: nosniff  
- `X-XSS-Protection`: 1; mode=block
- `Strict-Transport-Security`: max-age=31536000
- `Content-Security-Policy`: Configuré selon l'environnement

### 5. Gestion Sécurisée des Erreurs

#### En Production

- ❌ Pas de stack traces exposées
- ❌ Pas de détails d'implémentation
- ✅ Messages d'erreur génériques
- ✅ Logging détaillé côté serveur uniquement

#### Codes d'Erreur Standardisés

```javascript
400 - Bad Request (validation échouée)
401 - Unauthorized (authentification requise)
403 - Forbidden (permissions insuffisantes)
404 - Not Found (ressource inexistante)
500 - Internal Server Error (erreur serveur)
```

### 6. Protection CORS

```javascript
Origines autorisées (production) : Liste blanche spécifique
Méthodes : GET, POST, PUT, PATCH, DELETE
Headers : Content-Type, Authorization, X-API-Key
```

## 🐛 Signalement de Vulnérabilités

### Processus de Report

Si vous découvrez une vulnérabilité de sécurité, veuillez :

1. **NE PAS** créer d'issue publique GitHub
2. Envoyer un email à : **<security@agrismart-ci.com>**
3. Inclure :
   - Description de la vulnérabilité
   - Étapes pour reproduire
   - Impact potentiel
   - Suggestion de correctif (optionnel)

### Délais de Réponse

- **Accusé de réception** : 48 heures
- **Première analyse** : 7 jours
- **Correctif déployé** : 30 jours (selon gravité)

### Reconnaissance

Les chercheurs en sécurité contribuant de manière responsable seront reconnus dans notre Hall of Fame (sauf demand d'anonymat).

## ✅ Checklist de Sécurité pour Développeurs

Avant chaque pull request, vérifiez :

### Code

- [ ] Toutes les entrées utilisateur sont validées (express-validator)
- [ ] Aucun mot de passe ou secret en dur
- [ ] Variables sensibles dans `.env` (pas de commit)
- [ ] Queries DB via Prisma (pas de SQL raw)
- [ ] Gestion des erreurs sans fuite d'information
- [ ] Commentaires JSDoc pour fonctions publiques

### Tests

- [ ] Tests de sécurité passent (`npm test tests/security.test.js`)
- [ ] Script d'audit passe (`node scripts/security-audit.js`)
- [ ] Couverture de code > 80% sur nouveaux fichiers
- [ ] Tests d'autorisation pour nouveaux endpoints

### Configuration

- [ ] Headers de sécurité configurés
- [ ] Rate limiting sur nouveaux endpoints sensibles
- [ ] Permissions RBAC définies
- [ ] Logs configurés pour actions sensibles

## 🔍 Audit de Sécurité

### Tests Automatisés

```bash
# Tous les tests de sécurité
docker exec agrismart_api npm test -- tests/security.test.js
docker exec agrismart_api npm test -- tests/auth-security.test.js

# Script d'audit complet
docker exec agrismart_api node scripts/security-audit.js

# Avec couverture
docker exec agrismart_api npm test -- --coverage
```

### Audit Manuel

1. **Review de code** : Pair programming pour code sensible
2. **Penetration testing** : Tests manuels d'injection et escalade de privilèges
3. **Dependency audit** : `npm audit` mensuel
4. **Log review** : Analyse hebdomadaire des tentatives d'intrusion

## 📊 Conformité aux Normes

### OWASP Top 10 (2021)

| # | Vulnérabilité | Status | Protection |
|---|---------------|--------|------------|
| A01 | Broken Access Control | ✅ | RBAC + JWT + Tests |
| A02 | Cryptographic Failures | ✅ | bcrypt + HTTPS |
| A03 | Injection | ✅ | Prisma + Validation |
| A04 | Insecure Design | ✅ | Architecture revue |
| A05 | Security Misconfiguration | ✅ | Helmet + CSP |
| A06 | Vulnerable Components | 🔄 | npm audit mensuel |
| A07 | Auth Failures | ✅ | Rate limiting + JWT |
| A08 | Data Integrity Failures | ✅ | Validation stricte |
| A09 | Logging Failures | ✅ | Winston + Monitoring |
| A10 | SSRF | ⚠️ | Validation URLs |

**Légende** : ✅ Implémenté | 🔄 En cours | ⚠️ À améliorer

### ISO 27001

- **A.9.4** - Contrôle d'accès aux systèmes : ✅
- **A.12.4** - Logging et monitoring : ✅
- **A.12.6** - Gestion vulnérabilités : 🔄
- **A.14** - Développement sécurisé : ✅

## 🔐 Bonnes Pratiques de Développement

### Gestion des Secrets

```javascript
// ❌ MAUVAIS
const apiKey = 'sk_live_1234567890';

// ✅ BON
const apiKey = process.env.API_KEY;
```

### Validation des Entrées

```javascript
// ❌ MAUVAIS
app.post('/user', (req, res) => {
  const userId = req.body.id;
  // Utilisation directe
});

// ✅ BON
const { validators } = require('./middlewares/validation');
app.post('/user', [
  validators.uuid('id', 'body'),
  validate
], controller);
```

### Queries DB

```javascript
// ❌ MAUVAIS
const result = await db.query(`SELECT * FROM users WHERE id = ${userId}`);

// ✅ BON
const result = await prisma.user.findUnique({ where: { id: userId } });
```

### Gestion des Erreurs

```javascript
// ❌ MAUVAIS
catch (error) {
  res.status(500).json({ error: error.stack });
}

// ✅ BON
catch (error) {
  logger.error('Erreur traitement', { error, userId });
  res.status(500).json({ 
    success: false,
    message: 'Erreur serveur' 
  });
}
```

## 📞 Contact

- **Email sécurité** : <security@agrismart-ci.com>
- **Documentation** : <https://docs.agrismart-ci.com/security>
- **Status page** : <https://status.agrismart-ci.com>

## 📜 Versions Supportées

| Version | Supportée | Fin du support |
|---------|-----------|----------------|
| 1.x.x   | ✅        | Active         |
| 0.x.x   | ❌        | -              |

---

**Dernière mise à jour** : 2025-12-21  
**Version du document** : 1.0.0
