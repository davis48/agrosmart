# Docker Build Optimization Guide

## Dockerfile Development vs Production

### Development (Dockerfile)
**Optimisations appliquées:**
1. ✅ **Layer Caching Optimal**: Séparation `package.json` → `npm ci` → `prisma/` → `npx prisma generate`
2. ✅ **Hot Reload Ready**: Code source copié en dernier layer
3. ✅ **Dev Dependencies Included**: Tous les packages de développement disponibles

**Structure des layers (du plus stable au plus volatile):**
```dockerfile
1. Base image (node:20-slim)
2. System packages (openssl, wget)
3. package.json + package-lock.json
4. npm ci (cache invalidé seulement si package*.json change)
5. prisma/ schema
6. npx prisma generate (cache invalidé seulement si schema change)
7. Code source (invalidé à chaque changement)
```

**Bénéfices:**
- Rebuild < 5s si seul le code change (layers 1-6 en cache)
- Rebuild ~30s si schema Prisma change (layers 1-4 en cache)
- Rebuild ~2min si dependencies changent (layers 1-2 en cache)

### Production (Dockerfile.prod)
**Optimisations appliquées:**
1. ✅ **Multi-stage Build**: Builder stage séparé du runtime
2. ✅ **Production Dependencies Only**: `npm ci --only=production` (pas de devDependencies)
3. ✅ **Minimal Runtime Image**: Seulement les fichiers nécessaires copiés
4. ✅ **Security**: Non-root user (nodejs:1001)
5. ✅ **Signal Handling**: Tini pour PID 1 reaping
6. ✅ **Health Checks**: Endpoint /health monitoré

**Structure multi-stage:**
```dockerfile
Stage 1: Builder
- npm ci --only=production
- prisma generate
- Code source filtré (src/ et scripts/ seulement)

Stage 2: Runtime
- Copie UNIQUEMENT node_modules, prisma, src, scripts
- Pas de tests/, coverage/, docs/, etc.
- Image finale plus légère (~150MB vs ~300MB)
```

**Fichiers exclus en production:**
- tests/
- coverage/
- Dockerfile, docker-compose.yml
- README.md, documentation
- devDependencies (eslint, jest, etc.)

## Build Commands

### Development
```bash
# Build dev image
docker build -f backend/Dockerfile -t agrismart-backend:dev backend/

# Build et run avec compose
docker-compose up --build backend

# Rebuild rapide (cache utilisé)
docker-compose build backend
```

### Production
```bash
# Build production image
docker build -f backend/Dockerfile.prod -t agrismart-backend:prod backend/

# Build avec compose production
docker-compose -f docker-compose.prod.yml build backend

# Tag pour registry
docker tag agrismart-backend:prod registry.example.com/agrismart-backend:1.0.0
```

## Cache Invalidation

### Ce qui invalide le cache
| Changement | Layers reconstruits | Temps |
|------------|---------------------|-------|
| Code source uniquement | Layer 7 | ~5s |
| Schema Prisma | Layers 6-7 | ~30s |
| package.json | Layers 4-7 | ~2min |
| Dockerfile commands | Tous | ~3min |

### Best Practices
1. **Ne pas** modifier package.json fréquemment en dev
2. **Éviter** de changer l'ordre des layers
3. **Utiliser** `.dockerignore` pour exclure les fichiers inutiles
4. **Commit** package-lock.json pour reproductibilité

## .dockerignore

Fichiers exclus du build context:
```
node_modules/
npm-debug.log
coverage/
.git/
.env*
*.test.js
*.spec.js
README.md
```

## Image Size Comparison

| Stage | Size | Includes |
|-------|------|----------|
| Dev (avec devDependencies) | ~350MB | eslint, jest, nodemon, etc. |
| Prod Builder | ~280MB | Production dependencies |
| Prod Runtime (final) | ~150MB | Minimum nécessaire |

## Monitoring

### Health Check
```bash
# Tester le health check
docker inspect --format='{{json .State.Health}}' <container_id>

# Logs du health check
docker logs <container_id> | grep health
```

### Layer Analysis
```bash
# Voir la taille de chaque layer
docker history agrismart-backend:prod

# Analyser les layers avec dive
dive agrismart-backend:prod
```

## Performance Tips

### Build Time
1. Use `npm ci` instead of `npm install` (plus rapide, déterministe)
2. Separate dependencies from source code layers
3. Use multi-stage builds for production
4. Minimize COPY operations

### Runtime Performance
1. Non-root user (sécurité + permissions)
2. Tini for signal handling (shutdown graceful)
3. Health checks pour monitoring
4. Alpine base image (plus léger)

## Troubleshooting

### Cache pas utilisé
```bash
# Forcer rebuild sans cache
docker build --no-cache -f backend/Dockerfile .

# Voir ce qui a changé
docker diff <container_id>
```

### Image trop grosse
```bash
# Analyser les layers
docker history --no-trunc agrismart-backend:prod

# Identifier les gros fichiers
docker run --rm agrismart-backend:prod du -sh /*
```

### Prisma Client pas généré
```bash
# Rebuild avec logs
docker build --progress=plain -f backend/Dockerfile.prod .

# Vérifier la présence du client
docker run --rm agrismart-backend:prod ls -la node_modules/.prisma/
```
