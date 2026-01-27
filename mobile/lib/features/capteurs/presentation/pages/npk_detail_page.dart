import 'package:flutter/material.dart';
import '../../domain/entities/sensor.dart';

class NpkDetailPage extends StatelessWidget {
  final Sensor capteur;

  const NpkDetailPage({super.key, required this.capteur});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(capteur.nom),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildElementCard(context, 'Azote (N)', capteur.nitrogen ?? 0, 'mg/kg', Colors.blue, 50, 200)),
                const SizedBox(width: 12),
                Expanded(child: _buildElementCard(context, 'Phosphore (P)', capteur.phosphorus ?? 0, 'mg/kg', Colors.orange, 30, 100)),
              ],
            ),
            const SizedBox(height: 12),
            _buildElementCard(context, 'Potassium (K)', capteur.potassium ?? 0, 'mg/kg', Colors.purple, 150, 300),
            
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Interprétation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _buildInterpretation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.eco, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              "Capteur NPK",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              "Dernière mesure: ${_formatDate(capteur.lastUpdate)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 _buildBadge('Batterie ${capteur.niveauBatterie.toInt()}%', Icons.battery_std),
                 const SizedBox(width: 12),
                 _buildBadge(capteur.signalForce, Icons.signal_cellular_alt),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildElementCard(BuildContext context, String name, double value, String unit, Color color, double minOptimal, double maxOptimal) {
    String status = 'Optimal';
    Color statusColor = Colors.green;
    if (value < minOptimal) {
      status = 'Faible';
      statusColor = Colors.orange;
    } else if (value > maxOptimal) {
      status = 'Élevé';
      statusColor = Colors.red;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (value / (maxOptimal * 1.5)).clamp(0.0, 1.0),
                  backgroundColor: color.withOpacity(0.1),
                  color: color,
                  strokeWidth: 8,
                ),
                Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretation(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Santé du Sol",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "L'équilibre NPK semble correct pour la culture de cacao. Cependant, surveillez le niveau de phosphore qui est proche de la limite basse.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to recommendations
              },
              icon: const Icon(Icons.recommend),
              label: const Text("Voir les recommandations de fertilisation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
