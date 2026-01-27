# ========================================
# Dockerfile - AI Service
# AgriSmart CI - Service IA
# ========================================

FROM python:3.10-slim

# Informations de build
LABEL maintainer="AgriSmart CI Team"
LABEL description="AI Service for AgriSmart CI - Plant Disease Detection"

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Dossier de travail
WORKDIR /app

# Copier requirements
COPY requirements.txt .

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code source
COPY . .

# Variables d'environnement
ENV FLASK_ENV=production
ENV PORT=5001
ENV PYTHONUNBUFFERED=1

# Créer le dossier models si nécessaire
RUN mkdir -p /app/models

# Exposer le port
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1

# Démarrage avec Gunicorn pour production
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "--timeout", "120", "app:app"]
