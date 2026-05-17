import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required int gender,
    required DateTime birthDate,
  });

  Future<UserModel> login({required String email, required String password});

  Future<void> logout();
  Future<void> resetPassword({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  AuthRemoteDataSourceImpl({required this.dioClient, required this.sharedPreferences});

  @override
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required int gender,
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
          'confirmPassword': confirmPassword,
          'role': 0,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final createdUserId = responseData != null && responseData['id'] != null
            ? responseData['id'].toString()
            : '0';

        if (responseData != null && responseData['id'] != null) {
          return UserModel(
            id: createdUserId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            role: '0',
            createdAt: DateTime.now(),
          );
        }
      }

      throw ServerException(
        response.data?['message'] ?? 'Unexpected response from server',
      );
    } on DioException catch (e) {
      if ((e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) &&
          e.response != null &&
          (e.response?.statusCode == 200 || e.response?.statusCode == 201) &&
          e.response?.data != null &&
          e.response?.data['id'] != null) {
        return UserModel(
          id: e.response!.data['id'].toString(),
          firstName: firstName,
          lastName: lastName,
          email: email,
          role: '0',
          createdAt: DateTime.now(),
        );
      }
      _handleDioException(e);
      rethrow;
    }
  }

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

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        // Handle token if present
        if (response.data is Map<String, dynamic> && response.data['token'] != null) {
          final String token = response.data['token'];
          dioClient.setAuthToken(token);
          await sharedPreferences.setString('CACHED_AUTH_TOKEN', token);
        } else if (response.data is String) {
          dioClient.setAuthToken(response.data);
          await sharedPreferences.setString('CACHED_AUTH_TOKEN', response.data);
        }

        return UserModel.fromJson(
            response.data is String ? {} : response.data as Map<String, dynamic>);
      }

      throw ServerException(
        response.data?['message'] ?? 'Unexpected response from server',
      );
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    // 1. Always clear tokens locally first to ensure safe logout
    await sharedPreferences.remove('CACHED_AUTH_TOKEN');
    dioClient.clearAuthToken();

    // 2. Attempt to notify the server
    try {
      await dioClient.dio.post(ApiConstants.logout);
    } catch (e) {
      // Suppress any errors (network, server, etc.)
      // Local session is already cleared, so the user is logged out safely.
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
    // Handle timeout separately
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        throw NetworkException(
          'Request timed out. Please check your connection and try again.',
        );
      default:
        break;
    }

    // Handle HTTP errors
    switch (e.response?.statusCode) {
      case 400:
        throw ServerException(e.response?.data['message'] ?? 'Bad request');
      case 401:
        throw UnauthorizedException(
          e.response?.data['message'] ?? 'Unauthorized',
        );
      case 404:
        throw NotFoundException(e.response?.data['message'] ?? 'Not found');
      case 409:
        throw ServerException(
          e.response?.data['message'] ?? 'Email already exists',
        );
      default:
        throw ServerException(
          e.response?.data['message'] ?? 'Something went wrong',
        );
    }
  }
}
