# 🔐 GUIDE DE SÉCURITÉ - Actions Requises

## ⚠️ Alerte GitGuardian Détectée

**Date**: 9 février 2026  
**Fichier**: `backend/scripts/seed_admin.js`  
**Problème**: Mot de passe en dur `'Admin@2024!'` commité dans l'historique Git  
**Statut**: ✅ **CORRIGÉ** dans ce commit

---

## ✅ Corrections Appliquées

### 1. Scripts Sécurisés

| Fichier | Avant | Après |
|---------|-------|-------|
| `seed_admin.js` | `password: 'Admin@2024!'` | `password: process.env.ADMIN_PASSWORD \|\| 'ChangeMe@2024!'` |
| `verify_api_contract.js` | `password: 'StrongPassword123!'` | `password: process.env.TEST_USER_PASSWORD \|\| 'TestPassword123!'` |
| `seed-complete.js` | `bcrypt.hash('password123', 12)` | `bcrypt.hash(process.env.SEED_DEFAULT_PASSWORD \|\| 'DevSeed@2024!', 12)` |

### 2. Nouveau Fichier

- ✅ `backend/.env.scripts.example` créé pour documenter les variables de dev

### 3. GitIgnore Vérifié

- ✅ `.env` est bien ignoré
- ✅ `.credentials-backup` est bien ignoré
- ✅ Aucun fichier sensible ne sera commité

---

## 🚨 Actions Requises AVANT de Push

### Option 1: Rotation des Secrets (Recommandé)

Si le mot de passe `Admin@2024!` était utilisé sur un système réel :

1. **Le changer immédiatement** sur tous les systèmes où il est utilisé
2. Configurer un nouveau mot de passe fort via variable d'environnement
3. Ne JAMAIS réutiliser `Admin@2024!`

```bash
# Sur le serveur de production, définir un nouveau mot de passe
export ADMIN_PASSWORD="$(openssl rand -base64 24)"
echo "Nouveau mot de passe admin: $ADMIN_PASSWORD"
```

### Option 2: Nettoyer l'Historique Git (Optionnel mais recommandé)

Si vous voulez supprimer complètement le mot de passe de l'historique Git :

```bash
# ⚠️ ATTENTION: Cela réécrit l'historique git!
# Tous les collaborateurs devront re-cloner le repo

# 1. Créer un backup du repo
cd ..
cp -r agriculture agriculture-backup

# 2. Retourner dans le repo
cd agriculture

# 3. Utiliser git filter-repo (installer si nécessaire)
# brew install git-filter-repo  # macOS
# sudo apt install git-filter-repo  # Linux

# 4. Purger le mot de passe de l'historique
git filter-repo --invert-paths --path backend/scripts/seed_admin.js \
  --force --refs refs/heads/main

# Ou utiliser BFG Repo-Cleaner (alternative)
# java -jar bfg.jar --replace-text passwords.txt

# 5. Force push (⚠️ destructif!)
git push origin --force --all
git push origin --force --tags
```

**Note**: Cette opération est **destructive** et **réécrit l'historique**. Tous les collaborateurs devront:
```bash
git fetch origin
git reset --hard origin/main
```

### Option 3: Invalider le Secret (Minimum requis)

Si vous ne pouvez pas nettoyer l'historique :

1. ✅ S'assurer que `Admin@2024!` n'est JAMAIS utilisé en production
2. ✅ Utiliser des mots de passe générés aléatoirement
3. ✅ Documenter que ce secret est compromis

---

## 📋 Checklist Avant Push

- [x] Scripts modifiés pour utiliser des variables d'environnement
- [x] `.env` dans `.gitignore`
- [x] Nouveau fichier `.env.scripts.example` créé
- [ ] ⚠️ **Décider** : Nettoyer l'historique git OU invalider le secret
- [ ] Vérifier qu'aucun `.env` n'est dans le staging: `git status | grep .env`
- [ ] Vérifier le diff: `git diff backend/scripts/`

```bash
# Commandes de vérification
git status | grep -E '\.env$|\.env\.'
git check-ignore .env
```

---

## 🔒 Bonnes Pratiques de Sécurité

### Pour le Développement

1. **Utiliser `.env.example`** pour documenter les variables
2. **Ne JAMAIS** commiter les fichiers `.env`
3. **Utiliser des mots de passe différents** pour dev/staging/prod
4. **Générer des mots de passe forts**:
   ```bash
   openssl rand -base64 32
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   ```

### Pour la Production

1. **Variables d'environnement** injectées par le système (Docker, Kubernetes, etc.)
2. **Secrets Manager** (AWS Secrets Manager, HashiCorp Vault, etc.)
3. **Rotation régulière** des mots de passe
4. **Audit des accès** et logs d'authentification

### Outils de Sécurité

- ✅ **GitGuardian** : Détection automatique (déjà actif sur votre repo)
- ✅ **git-secrets** : Hook pre-commit pour éviter les fuites
  ```bash
  git clone https://github.com/awslabs/git-secrets
  cd git-secrets && make install
  cd /path/to/agriculture
  git secrets --install
  git secrets --register-aws
  ```
- ✅ **gitleaks** : Scanner de secrets dans git
  ```bash
  brew install gitleaks
  gitleaks detect --source . --verbose
  ```

---

## 📞 Contact

Si vous avez des questions sur la sécurité de ce projet, consultez :
- [DEPLOYMENT.md](./DEPLOYMENT.md) pour le déploiement sécurisé
- [.env.production.example](.env.production.example) pour les variables de prod
- [backend/.env.scripts.example](backend/.env.scripts.example) pour les variables de dev

---

## ✅ Statut Actuel

- **Mots de passe en dur** : ✅ Supprimés du code
- **Variables d'environnement** : ✅ Implémentées
- **GitIgnore** : ✅ Configuré correctement
- **Historique Git** : ⚠️ Contient encore l'ancien mot de passe (voir Options ci-dessus)

**Ce commit corrige le problème pour l'avenir. Pour nettoyer l'historique, suivez l'Option 2 ci-dessus.**
