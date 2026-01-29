# 📡 AgriSmart CI - IoT Service

Gateway pour la collecte et le traitement des données capteurs.

## 🛠️ Stack Technique

- **Node.js**
- **MQTT** (Mosquitto)
- **InfluxDB** (Time-series DB)

## 🏗️ Architecture

Le service IoT agit comme gateway entre les capteurs physiques et le backend :

```mermaid
graph LR
    subgraph Field["🌾 Terrain"]
        Sensor1["🌡️ Capteur 1<br/>(Température)"]
        Sensor2["💧 Capteur 2<br/>(Humidité)"]
        Sensor3["📊 Capteur 3<br/>(pH du sol)"]
    end

    subgraph IoTService["📡 IoT Service"]
        MQTT["MQTT Broker<br/>(Mosquitto)<br/>Port: 1883"]
        Processor["Data Processor<br/>(Validation + Transformation)"]
        AlertEngine["Alert Engine<br/>(Seuils + Règles)"]
    end

    subgraph Storage["💾 Stockage"]
        InfluxDB["InfluxDB<br/>(Séries temporelles)"]
    end

    subgraph Backend["🔧 Backend"]
        API["Backend API<br/>(Webhooks)"]
    end

    Sensor1 -->|Publish| MQTT
    Sensor2 -->|Publish| MQTT
    Sensor3 -->|Publish| MQTT
    MQTT --> Processor
    Processor --> InfluxDB
    Processor --> AlertEngine
    AlertEngine -->|HTTP POST| API

    style MQTT fill:#9C27B0
    style Processor fill:#2196F3
    style AlertEngine fill:#FF9800
    style InfluxDB fill:#4CAF50
```

### Topics MQTT

- `agrosmart/sensors/{sensorId}/temperature`
- `agrosmart/sensors/{sensorId}/humidity`
- `agrosmart/sensors/{sensorId}/soil_ph`
- `agrosmart/sensors/{sensorId}/status`

## 🐳 Docker (Recommandé)

Le service IoT fait partie de la stack Docker Compose :

```bash
# Depuis la racine du projet
docker-compose up -d

# Voir les logs du service IoT
docker-compose logs -f iot_service

# Redémarrer le service IoT
docker-compose restart iot_service

# Vérifier le broker MQTT
docker-compose logs -f mosquitto
```

### Services Connexes

- **MQTT Broker** : localhost:1883
- **InfluxDB** : <http://localhost:8086>
- **IoT Service** : <http://localhost:4000>

## 🚀 Fonctionnement

Ce service écoute les messages MQTT provenant des capteurs physiques, traite les données, et les stocke dans InfluxDB pour une analyse temporelle. Il notifie également le Backend principal via API en cas d'alertes.
