# Migration vers le Logger Centralisé (B-ARC-01)

## Problème
Le backend utilise un mélange de `console.log`, `console.error`, et `console.warn` au lieu du logger sécurisé centralisé.

## Solution
Le fichier `src/config/logger.js` fournit déjà un logger complet avec:
- Masquage automatique des données sensibles
- Logging conditionnel (dev uniquement)
- Niveaux appropriés (dev, debug, info, warn, error)

## Fichiers à Migrer

### Contrôleurs (Haute Priorité)
- [ ] `gamificationController.js` - 4 console.error
- [ ] `analyticsController.js` - 2 console.error
- [ ] `equipmentController.js` - 9 console.error
- [ ] `diagnosticsController.js` - 5 console.error
- [ ] `paymentController.js` - 2 console.error
- [ ] `weatherController.js` - 3 console.error
- [ ] `chatController.js` - 4 console.error
- [ ] `groupPurchasesController.js` - 2 console.error
- [ ] `formationController.js` - 8 console.error

### Services (Moyenne Priorité)
- [ ] `passwordService.js` - 3 console.error

### Middlewares (Basse Priorité)
- [ ] `devSecurity.js` - Accepté (logging dev seulement)
- [ ] `validation.js` - Accepté (utilise déjà [DEV] prefix)
- [ ] `errorHandler.js` - À réviser

## Transformation

### Avant
```javascript
console.error('Error fetching data:', error);
```

### Après
```javascript
const { errorLog } = require('../config/logger');
// ...
errorLog('CONTEXT', error, { additionalInfo: 'value' });
```

## Exemple de Migration

```javascript
// Avant
const myController = {
  async getData(req, res) {
    try {
      const data = await service.getData();
      res.json(data);
    } catch (error) {
      console.error('Error fetching data:', error);
      res.status(500).json({ error: 'Internal error' });
    }
  }
};

// Après
const { errorLog, debugLog } = require('../config/logger');

const myController = {
  async getData(req, res) {
    try {
      debugLog('getData', 'Fetching data for user:', req.userId);
      const data = await service.getData();
      res.json(data);
    } catch (error) {
      errorLog('getData', error, { userId: req.userId });
      res.status(500).json({ error: 'Internal error' });
    }
  }
};
```

## Script de Migration Automatique

Pour accélérer la migration, utilisez cette commande regex:

```bash
# Remplacer console.error par errorLog
find src/controllers -name "*.js" -exec sed -i '' \
  's/console\.error(\([^)]*\), error)/errorLog(\1, error, {})/g' {} \;
```

## Prochaines Étapes

1. Ajouter l'import du logger en haut de chaque fichier
2. Remplacer les appels console.* par les fonctions logger appropriées
3. Ajouter un contexte significatif à chaque log
4. Tester que les logs s'affichent correctement

## Notes
- En production, seuls `infoLog`, `warnLog`, et `errorLog` s'affichent
- `devLog` et `debugLog` sont automatiquement désactivés en production
- Toutes les données sensibles sont automatiquement masquées
