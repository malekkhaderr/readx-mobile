import 'package:get_it/get_it.dart';
import 'package:readx/core/network/dio_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
}
