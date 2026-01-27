import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../core/error/failures.dart';
import '../models/cached_dashboard_data.dart';
import '../models/dashboard_data_model.dart';

abstract class DashboardLocalDataSource {
  Future<DashboardDataModel> getLastDashboardData();
  Future<void> cacheDashboardData(DashboardDataModel data);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final Isar isar;

  DashboardLocalDataSourceImpl({required this.isar});

  @override
  Future<DashboardDataModel> getLastDashboardData() async {
    final cachedData = await isar.cachedDashboardDatas
        .where()
        .keyEqualTo('dashboard_summary')
        .findFirst();

    if (cachedData != null && cachedData.json != null) {
      return DashboardDataModel.fromJson(json.decode(cachedData.json!));
    } else {
      throw const CacheFailure('Aucune donnée en cache');
    }
  }

  @override
  Future<void> cacheDashboardData(DashboardDataModel data) async {
    final cachedData = CachedDashboardData()
      ..key = 'dashboard_summary'
      ..json = json.encode(data.toJson())
      ..lastUpdated = DateTime.now();

    await isar.writeTxn(() async {
      await isar.cachedDashboardDatas.put(cachedData);
    });
  }
}
