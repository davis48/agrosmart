import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/presentation/pages/capteur_detail_page.dart';
import 'package:agriculture/features/capteurs/presentation/pages/npk_detail_page_v2.dart';

class CapteursPage extends StatefulWidget {
  const CapteursPage({super.key});

  @override
  State<CapteursPage> createState() => _CapteursPageState();
}

class _CapteursPageState extends State<CapteursPage> {
  @override
  void initState() {
    super.initState();
    // Ensure sensors are loaded
    context.read<SensorBloc>().add(LoadSensors());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<SensorBloc, SensorState>(
        builder: (context, state) {
          if (state is SensorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Sensor> sensors = [];
          if (state is SensorLoaded) {
            sensors = state.sensors;
          }

          // Group sensors by Parcelle
          final Map<String, List<Sensor>> parcellesSensors = {};
          for (var s in sensors) {
            final parcelle = s.parcelleNom ?? "Non assigné";
            if (!parcellesSensors.containsKey(parcelle)) {
              parcellesSensors[parcelle] = [];
            }
            parcellesSensors[parcelle]!.add(s);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        "Données en temps réel",
                        Icons.show_chart,
                      ),
                      const SizedBox(height: 12),

                      if (parcellesSensors.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Aucun capteur connecté"),
                          ),
                        ),

                      ...parcellesSensors.entries.map((entry) {
                        return _buildParcelleCard(entry.key, entry.value);
                      }),

                      const SizedBox(height: 24),
                      _buildSectionTitle("Historique 7 jours"),
                      const SizedBox(height: 12),
                      _buildHistoryCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3), // Blue
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Monitoring IoT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => context.read<SensorBloc>().add(LoadSensors()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Surveillance en temps réel",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildParcelleCard(String parcelleName, List<Sensor> sensors) {
    // Determine overall status
    // If any sensor is critical, parcelle is critical
    bool isCritique = sensors.any(
      (s) => s.status == 'critical' || s.status == 'defaillant',
    );
    bool isWarning = !isCritique && sensors.any((s) => s.status == 'warning');

    Color statusColor = Colors.green;
    if (isCritique) {
      statusColor = Colors.red;
    } else if (isWarning) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                parcelleName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Try to find Temp, Hum, and pH sensors or similar
              // If multiple, just take first found for simplicity of the card summary
              _buildSensorMetric(
                sensors,
                'temperature',
                "28°C",
                Icons.thermostat,
                Colors.red,
              ),
              _buildSensorMetric(
                sensors,
                'humidite',
                "65%",
                Icons.water_drop,
                Colors.blue,
              ),
              _buildSensorMetric(
                sensors,
                'ph',
                "pH 6.2",
                Icons.flash_on,
                Colors.orange,
              ),
              _buildSensorMetric(
                sensors,
                'npk',
                "NPK",
                Icons.eco,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMetric(
    List<Sensor> sensors,
    String typeKeyword,
    String fallbackValue,
    IconData icon,
    Color color,
  ) {
    // Find sensor
    final sensor = sensors.firstWhere(
      (s) => s.type.toLowerCase().contains(typeKeyword.toLowerCase()),
      orElse: () => Sensor(
        id: '',
        code: '',
        nom: '',
        type: '',
        status: '',
        parcelleNom: '',
        niveauBatterie: 0.0,
        signalForce: 'faible',
        lastUpdate: DateTime.now(),
      ),
    );

    String displayValue = fallbackValue;
    if (sensor.id.isNotEmpty) {
      if (typeKeyword == 'npk') {
        displayValue = "NPK";
        if (sensor.nitrogen != null) displayValue = "N: ${sensor.nitrogen}";
      } else if (sensor.lastValue != null) {
        displayValue = "${sensor.lastValue!.toStringAsFixed(1)}";
        if (typeKeyword == 'temperature') displayValue += "°C";
        if (typeKeyword == 'humidite') displayValue += "%";
        if (typeKeyword == 'ph') displayValue = "pH $displayValue";
      } else {
        displayValue = "--";
      }
    } else {
      return Opacity(
        opacity: 0.3,
        child: _metricWidget(displayValue, icon, color),
      );
    }

    return GestureDetector(
      onTap: () {
        if (typeKeyword == 'npk') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NpkDetailPageV2(capteur: sensor)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CapteurDetailPage(capteur: sensor),
            ),
          );
        }
      },
      child: _metricWidget(displayValue, icon, color),
    );
  }

  Widget _metricWidget(String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for Chart
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                "Graphique des tendances",
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),

          // FAB in bottom right of card (as per mockup roughly)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFC107),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
