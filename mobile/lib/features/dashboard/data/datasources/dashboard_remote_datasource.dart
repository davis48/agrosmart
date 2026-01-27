import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../models/dashboard_data_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardDataModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardDataModel> getDashboardData() async {
    try {
      // In a real scenario, we might fetch these in parallel or from a single aggregated endpoint
      // For now, let's assume a single endpoint that returns everything
      final response = await dio.get('/dashboard/stats');
      return DashboardDataModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Erreur serveur');
    }
  }
}
