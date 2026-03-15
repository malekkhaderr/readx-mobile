import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
}
