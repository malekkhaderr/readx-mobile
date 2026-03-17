import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
  });

  Future<void> logout();

  Future<void> resetPassword({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.register,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
        },
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await dioClient.dio.post(
        ApiConstants.resetPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  void _handleDioException(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        throw ServerException(e.response?.data['message'] ?? 'Bad request');
      case 401:
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Unauthorized',
        );
      case 404:
        throw NotFoundException(e.response?.data['message'] ?? 'Not found');
      default:
        throw ServerException(
          e.response?.data['message'] ?? 'Something went wrong',
        );
    }
  }
}
