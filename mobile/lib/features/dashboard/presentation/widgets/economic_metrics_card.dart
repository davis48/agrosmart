import 'package:flutter/material.dart';
import '../../../analytics/domain/entities/analytics_data.dart';

class EconomicMetricsCard extends StatelessWidget {
  final AnalyticsData analytics;
  const EconomicMetricsCard({super.key, required this.analytics});
    @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Economic Metrics")));
  }
}
