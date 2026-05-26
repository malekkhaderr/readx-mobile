import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/author_dashboard_model.dart';
import '../models/author_book_model.dart';
import '../models/author_statistics_model.dart';
import '../models/publisher_request_model.dart';

abstract class AuthorDashboardRemoteDataSource {
  Future<AuthorDashboardOverview> getDashboard();
  Future<List<AuthorBook>> getBooks();
  Future<AuthorStatistics> getStatistics({int? bookId, int? categoryId});

  Future<List<PublisherRequestModel>> getMyRequests();
  Future<void> submitAddBookRequest(AddBookRequestModel request);
  Future<void> submitModifyBookRequest(ModifyBookRequestModel request);
  Future<void> submitRemoveBookRequest(RemoveBookRequestModel request);
}

class AuthorDashboardRemoteDataSourceImpl
    implements AuthorDashboardRemoteDataSource {
  final DioClient dioClient;

  AuthorDashboardRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthorDashboardOverview> getDashboard() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.authorDashboard);

      if (response.statusCode == 200 && response.data != null) {
        return AuthorDashboardOverview.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw ServerException(
        response.data?['message'] ?? 'Failed to load dashboard',
      );
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<List<AuthorBook>> getBooks() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.authorBooks);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data;

        if (response.data is List) {
          data = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          data = response.data['books'] ?? response.data['data'] ?? [];
        } else {
          data = [];
        }

        return data
            .map((json) => AuthorBook.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ServerException(
        response.data?['message'] ?? 'Failed to load books',
      );
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<AuthorStatistics> getStatistics({
    int? bookId,
    int? categoryId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (bookId != null) queryParameters['bookId'] = bookId;
      if (categoryId != null) queryParameters['categoryId'] = categoryId;

      final response = await dioClient.dio.get(
        ApiConstants.authorStatistics,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthorStatistics.fromJson(
            response.data as Map<String, dynamic>);
      }

      throw ServerException(
        response.data?['message'] ?? 'Failed to load statistics',
      );
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<List<PublisherRequestModel>> getMyRequests() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.publisherRequestsMy);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => PublisherRequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw ServerException(
        response.data?['message'] ?? 'Failed to load requests',
      );
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<void> submitAddBookRequest(AddBookRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.publisherRequests,
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          response.data?['message'] ?? 'Failed to submit request',
        );
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<void> submitModifyBookRequest(ModifyBookRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.publisherRequestsModify,
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          response.data?['message'] ?? 'Failed to submit request',
        );
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<void> submitRemoveBookRequest(RemoveBookRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.publisherRequestsRemove,
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          response.data?['message'] ?? 'Failed to submit request',
        );
      }
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
          e.response?.data['message'] ?? 'Conflict',
        );
      default:
        throw ServerException(
          e.response?.data['message'] ?? 'Something went wrong',
        );
    }
  }
}
