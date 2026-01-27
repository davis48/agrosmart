import 'package:flutter/material.dart';

class YieldPredictionCard extends StatelessWidget {
  final double prediction; // Tonnes
  final double confidence; // 0.0 to 1.0
  final List<String> factors;

  const YieldPredictionCard({
    super.key,
    required this.prediction,
    required this.confidence,
    required this.factors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prédiction de Rendement",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "Analyse IA",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${prediction.toStringAsFixed(1)} Tonnes",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text("Estimation totale", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                CircularProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.grey.shade200,
                  color: confidence > 0.8 ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text("Facteurs clés :", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: factors.map((f) => Chip(
                label: Text(f, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.green.shade200),
                visualDensity: VisualDensity.compact,
              )).toList(),
            )
          ],
        ),
      ),
    );
  }
}
