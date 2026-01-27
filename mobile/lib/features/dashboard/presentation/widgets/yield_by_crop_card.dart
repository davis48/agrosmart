import 'package:flutter/material.dart';
import '../../../analytics/domain/entities/analytics_data.dart';

class YieldByCropCard extends StatelessWidget {
  final List<RendementParCulture> rendements;
  const YieldByCropCard({super.key, required this.rendements});
    @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Yield Data")));
  }
}
