import '../../../../core/network/dio_client.dart';
import '../models/reader_level_model.dart';

class LevelsRemoteDataSource {
  final DioClient dioClient;

  LevelsRemoteDataSource({required this.dioClient});

  Future<List<ReaderLevel>> getAllLevels() async {
    final response = await dioClient.dio.get('/reader-levels');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((e) => ReaderLevel.fromJson(e)).toList();
    }
    throw Exception('Failed to load reader levels');
  }
}
