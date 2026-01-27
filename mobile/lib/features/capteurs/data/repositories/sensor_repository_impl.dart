import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../datasources/sensor_local_data_source.dart';
import 'package:agriculture/features/capteurs/data/datasources/sensor_remote_data_source.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';
import 'package:agriculture/features/capteurs/domain/repositories/sensor_repository.dart';

class SensorRepositoryImpl implements SensorRepository {
  final SensorRemoteDataSource remoteDataSource;
  final SensorLocalDataSource localDataSource;
  final InternetConnection networkInfo;

  SensorRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<Sensor>> getSensors() async {
    if (await networkInfo.hasInternetAccess) {
      try {
        final sensors = await remoteDataSource.getSensors();
        await localDataSource.cacheSensors(sensors);
        return sensors;
      } catch (e) {
        // If remote fails but we have internet (e.g. server error), try local
        return await localDataSource.getLastSensors();
      }
    } else {
      return await localDataSource.getLastSensors();
    }
  }

  @override
  Future<Sensor> getSensorById(String id) async {
    if (await networkInfo.hasInternetAccess) {
      try {
        return await remoteDataSource.getSensorById(id);
      } catch (e) {
        // Fallback logic could be complex for single item, simplistic here
        throw e; 
      }
    } else {
      // Simplistic: Fetch all local and find one
      final sensors = await localDataSource.getLastSensors();
      return sensors.firstWhere((s) => s.id == id);
    }
  }

  @override
  Future<List<SensorMeasure>> getSensorHistory(String id) async {
    // History might stay online-only for MVP or need its own cache
    if (await networkInfo.hasInternetAccess) {
      return await remoteDataSource.getSensorHistory(id);
    } else {
      return []; // Return empty if offline and not cached
    }
  }
}
