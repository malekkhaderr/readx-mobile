import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/home_response_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeResponse> getHome();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<HomeResponse> getHome() async {
    final response = await dioClient.dio.get(ApiConstants.booksHome);
    return HomeResponse.fromJson(response.data);
  }
}
