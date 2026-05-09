import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getMe();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  ProfileRemoteDataSourceImpl({
    required this.dioClient,
    required this.sharedPreferences,
  });

  @override
  Future<UserProfileModel> getMe() async {
    // Ensure the token is always present before the request
    final token = sharedPreferences.getString('CACHED_AUTH_TOKEN');
    if (token != null && token.isNotEmpty) {
      dioClient.setAuthToken(token);
    }

    try {
      final response = await dioClient.dio.get(ApiConstants.me);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null &&
          response.data is Map<String, dynamic>) {
        return UserProfileModel.fromJson(
            response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 401) {
        throw const UnauthorizedException('Session expired. Please log in again.');
      }

      throw ServerException(
        response.data?['message']?.toString() ?? 'Unexpected server response',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException(
            'Session expired. Please log in again.');
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const NetworkException(
              'Request timed out. Please check your connection.');
        case DioExceptionType.connectionError:
          throw const NetworkException(
              'No internet connection. Please try again.');
        default:
          throw ServerException(
            e.response?.data?['message']?.toString() ?? 'Something went wrong',
          );
      }
    }
  }
}
