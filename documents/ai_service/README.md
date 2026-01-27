# 🧠 AgriSmart CI - AI Service

Service de détection de maladies des plantes par vision par ordinateur.

## 🛠️ Stack Technique

- **Python** 3.11
- **FastAPI**
- **TensorFlow / Keras**

## 🏗️ Architecture

Le service IA utilise un modèle CNN (Convolutional Neural Network) pour détecter les maladies des plantes :

```mermaid
graph TB
    subgraph Client["📱 Client"]
        User["Producteur<br/>(Mobile App)"]
    end

    subgraph API["🔌 FastAPI Service"]
        Endpoint["/predict endpoint"]
        Validator["Image Validator<br/>(Format, Taille)"]
    end

    subgraph Processing["🔄 Pipeline de Traitement"]
        Preprocessor["Image Preprocessor<br/>(Resize, Normalize)"]
        Model["CNN Model<br/>(TensorFlow/Keras)"]
        Postprocessor["Result Processor<br/>(Confidence, Labels)"]
    end

    subgraph ML["🧠 ML Model"]
        InputLayer["Input: 224x224x3"]
        ConvLayers["Convolutional Layers<br/>(Feature Extraction)"]
        DenseLayers["Dense Layers<br/>(Classification)"]
        Output["Output: Disease Class<br/>+ Confidence Score"]
    end

    User -->|Upload Image| Endpoint
    Endpoint --> Validator
    Validator --> Preprocessor
    Preprocessor --> Model
    Model --> InputLayer
    InputLayer --> ConvLayers
    ConvLayers --> DenseLayers
    DenseLayers --> Output
    Output --> Postprocessor
    Postprocessor -->|JSON Response| User

    style Endpoint fill:#4CAF50
    style Model fill:#FF9800
    style ConvLayers fill:#2196F3
    style Output fill:#9C27B0
```

### Classes de Maladies Détectées

- Mildiou (Late Blight)
- Taches foliaires (Leaf Spot)
- Rouille (Rust)
- Mosaïque (Mosaic Virus)
- Plante saine (Healthy)

## 🐳 Docker (Recommandé)

Le service IA fait partie de la stack Docker Compose :

```bash
# Depuis la racine du projet
docker-compose up -d

# Voir les logs du service IA
docker-compose logs -f ai_service

# Redémarrer le service IA
docker-compose restart ai_service

# Rebuild après modifications de modèle
docker-compose up -d --build ai_service
```

### Build standalone (optionnel)

```bash
# Depuis le dossier ai_service
docker build -t agrismart-ai .
docker run -p 5001:5001 agrismart-ai
```

## 🚀 Utilisation

Le service expose une API REST sur le port **5001**.

- **Health Check**: `GET /health`
- **Prédiction**: `POST /predict` (Multipart file upload)

### Exemple de requête

```bash
curl -X POST http://localhost:5001/predict \
  -F "file=@plant_image.jpg"
```
