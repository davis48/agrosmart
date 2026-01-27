import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';
import '../../domain/entities/sensor.dart';
import '../widgets/sensor_history_chart.dart';
import '../../../../injection_container.dart' as di;

class CapteurDetailPage extends StatelessWidget {
  final Sensor capteur;

  const CapteurDetailPage({super.key, required this.capteur});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<SensorBloc>()..add(LoadSensorHistory(capteur.id)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(capteur.nom),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        _getTypeIcon(capteur.type),
                        size: 64,
                        color: _getTypeColor(capteur.type),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${capteur.lastValue?.toStringAsFixed(1) ?? '--'} ${capteur.unit ?? getUnite(capteur.type)}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(capteur.type),
                        ),
                      ),
                      Text(
                        capteur.nom,
                        style: const TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                       const SizedBox(height: 8),
                       _buildStatusBadge(capteur.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // History Chart
               const Align(
                alignment: Alignment.centerLeft,
                child: Text('Historique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                  child: BlocBuilder<SensorBloc, SensorState>(
                    builder: (context, state) {
                      if (state is SensorLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is SensorHistoryLoaded) {
                        if (state.history.isEmpty) {
                          return const Center(child: Text('Aucune donnée disponible'));
                        }
                        return SensorHistoryChart(
                          data: _mapHistoryToChart(state.history),
                          color: _getTypeColor(capteur.type),
                          unit: capteur.unit ?? getUnite(capteur.type),
                        );
                      } else if (state is SensorError) {
                        return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
  
              const SizedBox(height: 24),
              // Info Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                   _buildGridItem(Icons.battery_full, '${capteur.niveauBatterie.toStringAsFixed(0)}%', 'Batterie'),
                   _buildGridItem(Icons.location_on, capteur.parcelleNom ?? 'Non assigné', 'Localisation'),
                   _buildGridItem(Icons.update, _formatDate(capteur.lastUpdate), 'Mise à jour'),
                   _buildGridItem(Icons.wifi, capteur.signalForce, 'Signal'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ChartDataPoint> _mapHistoryToChart(List<SensorMeasure> history) {
    if (history.isEmpty) return [];
    // Sort by timestamp asc
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Take last 20 points if too many
    final points = history.length > 20 ? history.sublist(history.length - 20) : history;

    return points.map((m) => ChartDataPoint(
      '${m.timestamp.day}/${m.timestamp.month} ${m.timestamp.hour}h',
      m.value
    )).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String getUnite(String type) {
    switch (type.toLowerCase()) {
      case 'temperature': return '°C';
      case 'humidite': return '%';
      case 'ph': return 'pH';
      default: return '';
    }
  }

  Widget _buildStatusBadge(String status) {
     Color color;
     if (status.toLowerCase().contains('actif') || status.toLowerCase() == 'normal') {
       color = Colors.green;
     } else if (status.toLowerCase().contains('warning')) {
       color = Colors.orange;
     } else {
       color = Colors.red;
     }
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
       child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
     );
  }

  Widget _buildGridItem(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'humidite': return Colors.blue;
      case 'temperature': return Colors.orange;
      case 'ph': return Colors.purple;
      case 'npk': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'humidite': return Icons.water_drop;
      case 'temperature': return Icons.thermostat;
      case 'ph': return Icons.science;
      case 'npk': return Icons.eco;
      default: return Icons.sensors;
    }
  }
}
