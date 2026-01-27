import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';

class SensorModel extends Sensor {
  SensorModel({
    required super.id,
    required super.code,
    required super.nom,
    required super.type,
    required super.status,
    super.parcelleNom,
    required super.niveauBatterie,
    required super.signalForce,
    required super.lastUpdate,
    super.lastValue,
    super.unit,
    super.nitrogen,
    super.phosphorus,
    super.potassium,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    // Map signal level (int dBm or similar) to 'fort'/'moyen'/'faible'
    // This logic might need refinement based on real API data
    String signal = 'moyen';
    // if (json['signal'] > ...) signal = 'fort';

    return SensorModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      nom: json['nom'] ?? 'Capteur sans nom',
      type: json['type'] ?? 'Inconnu',
      status: json['statut'] ?? json['status'] ?? 'inactif',
      parcelleNom: json['parcelle_nom'], // Need join in backend query
      niveauBatterie: double.tryParse(json['niveau_batterie']?.toString() ?? '0') ?? 0.0,
      signalForce: signal, 
      lastUpdate: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      lastValue: double.tryParse(json['derniere_valeur']?.toString() ?? '0') ?? 0.0,
      unit: json['unite_mesure']?.toString(),
      nitrogen: double.tryParse(json['nitrogen']?.toString() ?? '0'),
      phosphorus: double.tryParse(json['phosphorus']?.toString() ?? '0'),
      potassium: double.tryParse(json['potassium']?.toString() ?? '0'),
    );
  }
}
