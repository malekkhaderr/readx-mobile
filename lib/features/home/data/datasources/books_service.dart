import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/book_detail_model.dart';
import '../models/book_comment_model.dart';
import '../models/rating_review_model.dart';

class BooksService {
  final DioClient dioClient;

  BooksService({required this.dioClient});

  Future<BookDetail> getBookDetail(int id) async {
    try {
      final response = await dioClient.dio.get('${ApiConstants.books}/$id?incrementView=1');
      return BookDetail.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<CommentListResponse> getComments(int bookId, {int page = 1, int pageSize = 10}) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.books}/$bookId/comments',
        queryParameters: {
          'pageNumber': page,
          'pageSize': pageSize,
        },
      );
      return CommentListResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<RatingReviewsResponse> getRatings(int bookId, {int page = 1, int pageSize = 10}) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.books}/$bookId/ratings',
        queryParameters: {
          'pageNumber': page,
          'pageSize': pageSize,
        },
      );
      return RatingReviewsResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addComment(int bookId, String body) async {
    try {
      await dioClient.dio.post(
        '${ApiConstants.books}/$bookId/comments',
        data: {'body': body},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateComment(int bookId, int commentId, String body) async {
    try {
      try {
        await dioClient.dio.put(
          '${ApiConstants.books}/$bookId/comments/$commentId',
          data: {'body': body},
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 405 || e.response?.statusCode == 404) {
          try {
            await dioClient.dio.patch(
              '${ApiConstants.books}/$bookId/comments/$commentId',
              data: {'body': body},
            );
          } on DioException catch (e2) {
            if (e2.response?.statusCode == 404) {
              await dioClient.dio.patch(
                '/comments/$commentId',
                data: {'body': body},
              );
            } else {
              rethrow;
            }
          }
        } else if (e.response?.statusCode == 404) {
          await dioClient.dio.put(
            '/comments/$commentId',
            data: {'body': body},
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(int bookId, int commentId) async {
    try {
      try {
        await dioClient.dio.delete('${ApiConstants.books}/$bookId/comments/$commentId');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          await dioClient.dio.delete('/comments/$commentId');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> voteComment(int bookId, int commentId, int voteType) async {
    try {
      await dioClient.dio.post(
        '${ApiConstants.books}/$bookId/comments/$commentId/vote',
        data: {'voteType': voteType},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReadingSession(int bookId) async {
    try {
      final response = await dioClient.dio.get('${ApiConstants.readingSessions}/$bookId');
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startReadingSession(int bookId) async {
    try {
      await dioClient.dio.post('${ApiConstants.readingSessions}/$bookId/start');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReadingProgress(int bookId, int currentPage, int readingTimeMinutes) async {
    try {
      await dioClient.dio.put(
        '${ApiConstants.readingSessions}/$bookId/progress',
        data: {
          'currentPage': currentPage,
          'readingTimeMinutes': readingTimeMinutes,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
