import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, DashboardData>> getDashboardData() async {
    try {
      final remoteData = await remoteDataSource.getDashboardData();
      await localDataSource.cacheDashboardData(remoteData);
      return Right(remoteData);
    } on ServerFailure catch (e) {
      // Fallback to local cache on server error
      try {
        final localData = await localDataSource.getLastDashboardData();
        return Right(localData);
      } catch (_) {
        return Left(e);
      }
    } catch (e) {
      // Fallback to local cache on network error
      try {
        final localData = await localDataSource.getLastDashboardData();
        return Right(localData);
      } catch (_) {
        return const Left(ServerFailure('Erreur inattendue et pas de cache'));
      }
    }
  }
}
