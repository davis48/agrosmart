import 'package:flutter/material.dart';
import '../../../analytics/domain/entities/analytics_data.dart';

class RoiCard extends StatelessWidget {
  final AnalyticsData analytics;
  const RoiCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Text("ROI Data")));
  }
}
