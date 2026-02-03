import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/parcelle.dart';
import '../widgets/yield_prediction_card.dart';

class ParcelleDetailPage extends StatelessWidget {
  final Parcelle parcelle;

  const ParcelleDetailPage({super.key, required this.parcelle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(parcelle.nom),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake Map Placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.green.shade100,
              child: Center(
                child: Icon(Icons.map, size: 64, color: Colors.green.shade300),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        parcelle.nom,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(parcelle.status),
                    ],
                  ),
                  Text(
                    '${parcelle.culture} • ${parcelle.typeSol} • ${parcelle.superficie} ha',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Métriques Actuelles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailMetric(
                        Icons.water_drop,
                        '${parcelle.humidite}%',
                        'Humidité',
                        Colors.blue,
                      ),
                      _buildDetailMetric(
                        Icons.thermostat,
                        '${parcelle.temperature}°C',
                        'Température',
                        Colors.orange,
                      ),
                      _buildDetailMetric(
                        Icons.terrain,
                        parcelle.typeSol,
                        'Sol',
                        Colors.brown,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const YieldPredictionCard(
                    prediction: 12.5,
                    confidence: 0.85,
                    factors: [
                      'Pluviométrie favorable',
                      'Sol riche',
                      'Aucun ravageur détecté',
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.water, color: Colors.white),
                    ),
                    title: const Text('Irrigation'),
                    subtitle: const Text('Dernière irrigation: Hier'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/irrigation'),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.science, color: Colors.white),
                    ),
                    title: const Text('Fertilisation'),
                    subtitle: const Text('Recommandation: NPK requis'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFertilisationDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFertilisationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.purple),
            SizedBox(width: 8),
            Text('Fertilisation'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFertilisationItem(
                'NPK 15-15-15',
                'Recommandé pour la croissance équilibrée',
                '200 kg/ha',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildFertilisationItem(
                'Urée (46% N)',
                'Pour renforcer la croissance végétative',
                '100 kg/ha',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildFertilisationItem(
                'Compost organique',
                'Améliore la structure du sol',
                '2 tonnes/ha',
                Colors.brown,
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Appliquer après une pluie légère ou irrigation',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plan de fertilisation enregistré'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Appliquer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilisationItem(
    String name,
    String description,
    String dose,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dose,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'healthy' || status == 'OPTIMAL'
        ? Colors.green
        : (status == 'warning' ? Colors.orange : Colors.red);
    String label = status == 'healthy' ? 'OPTIMAL' : status.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailMetric(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
