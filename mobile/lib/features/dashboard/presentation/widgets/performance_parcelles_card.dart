import 'package:flutter/material.dart';
import '../../../analytics/domain/entities/analytics_data.dart';

class PerformanceParcellesCard extends StatelessWidget {
  final List<PerformanceParcelle> parcelles;
  const PerformanceParcellesCard({super.key, required this.parcelles});
    @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Parcelle Performance")));
  }
}
