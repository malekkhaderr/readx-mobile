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
    try {
      final response = await dioClient.dio.get(ApiConstants.booksHome);
      final homeData = HomeResponse.fromJson(response.data);

      // Debug logging for image URLs
      for (var b in homeData.trendingBooks) {
        final rawUrl = b.coverImageUrl;
        final parsedUrl = Uri.parse(rawUrl).toString();
        print('Book: ${b.title}');
        print('  Raw URL: $rawUrl');
        print('  Parsed URL: $parsedUrl');
      }

      return homeData;
    } catch (e) {
      rethrow;
    }
  }
}
