import 'package:flutter/material.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';

class CriticalAlertsCard extends StatelessWidget {
  final List<Alert> criticalAlerts;
  const CriticalAlertsCard({super.key, required this.criticalAlerts});
    @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Critical Alerts")));
  }
}
