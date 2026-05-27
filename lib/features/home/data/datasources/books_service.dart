import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/book_detail_model.dart';
import '../models/book_comment_model.dart';
import '../models/rating_review_model.dart';

class BooksService {
  final DioClient dioClient;

  BooksService({required this.dioClient});

  Future<BookDetail> getBookDetail(int id, {bool incrementView = true}) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.books}/$id',
        queryParameters: {'incrementViewCount': incrementView},
      );
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

  /// Returns the current user's review for [bookId] or null if they haven't
  /// rated it yet (backend returns 404 with `{message}` in that case, which
  /// `validateStatus < 500` lets through as a normal Response).
  Future<RatingReviewItem?> getMyRating(int bookId) async {
    try {
      final response = await dioClient.dio
          .get('${ApiConstants.books}/$bookId/ratings/me');
      final code = response.statusCode ?? 0;
      if (code == 404) return null;
      if (code >= 200 && code < 300 && response.data is Map<String, dynamic>) {
        return RatingReviewItem.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Upserts the current user's rating + optional written review for
  /// [bookId]. Backend enforces `rating ∈ [0.5, 5.0]` in 0.5 steps; the text
  /// is optional — pass null/empty to leave it blank or to clear an existing
  /// one. Throws [RatingException] on 4xx with the backend message.
  Future<RatingReviewItem> upsertRating(
    int bookId,
    double rating, {
    String? text,
  }) async {
    try {
      final cleanText = text?.trim();
      final response = await dioClient.dio.post(
        '${ApiConstants.books}/$bookId/ratings',
        data: {
          'rating': rating,
          'text': (cleanText == null || cleanText.isEmpty) ? null : cleanText,
        },
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data is Map<String, dynamic>) {
        return RatingReviewItem.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw _extractRatingError(code, response.data);
    } on DioException catch (e) {
      throw _extractRatingError(e.response?.statusCode ?? 0, e.response?.data);
    }
  }

  /// Deletes the current user's review for [bookId]. Backend returns 204.
  Future<void> deleteMyRating(int bookId) async {
    try {
      final response =
          await dioClient.dio.delete('${ApiConstants.books}/$bookId/ratings');
      final code = response.statusCode ?? 0;
      if (code == 204 || code == 200) return;
      throw _extractRatingError(code, response.data);
    } on DioException catch (e) {
      throw _extractRatingError(e.response?.statusCode ?? 0, e.response?.data);
    }
  }

  RatingException _extractRatingError(int code, dynamic data) {
    String message = 'Could not save your rating. Please try again.';
    if (data is Map<String, dynamic>) {
      message = (data['message'] ?? data['error'] ?? message).toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }
    return RatingException(statusCode: code, message: message);
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

  /// Pushes a *delta* of reading time + the latest current page to the
  /// backend. Per the API contract `readingTimeMinutes` is the time read
  /// **since the last successful call** — the backend adds it to the server-
  /// side total and computes streak / tokens off the increment. Callers must
  /// reset their stopwatch on success (see ReadingSessionTracker).
  Future<ProgressUpdateResult> updateReadingProgress(
    int bookId,
    int currentPage,
    int readingTimeMinutes,
  ) async {
    final response = await dioClient.dio.put(
      '${ApiConstants.readingSessions}/$bookId/progress',
      data: {
        'currentPage': currentPage,
        'readingTimeMinutes': readingTimeMinutes,
      },
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      // DioClient.validateStatus allows 4xx through, so we have to throw
      // manually so callers (e.g. the reader's _saveProgress) can detect
      // a 409 "session completed" and stop further polls.
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: response.data is Map<String, dynamic>
            ? (response.data['message']?.toString())
            : null,
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProgressUpdateResult.fromJson(data);
    }
    return const ProgressUpdateResult(
      currentPage: 0,
      progressPercentage: 0,
      isCompleted: false,
      tokensEarned: 0,
    );
  }

  /// Buy book with USD. Returns the response body on success.
  /// Throws BuyException with the backend's error message on failure.
  Future<Map<String, dynamic>> buyWithUSD(int bookId) async {
    try {
      final response = await dioClient.dio
          .post('${ApiConstants.books}/$bookId/buyUSD');
      return _handleBuyResponse(response);
    } on DioException catch (e) {
      throw _extractBuyError(e);
    }
  }

  /// Buy book with Tokens. Returns the response body on success.
  /// Throws BuyException with the backend's error message on failure.
  Future<Map<String, dynamic>> buyWithTokens(int bookId) async {
    try {
      final response = await dioClient.dio
          .post('${ApiConstants.books}/$bookId/buyTokens');
      return _handleBuyResponse(response);
    } on DioException catch (e) {
      throw _extractBuyError(e);
    }
  }

  Map<String, dynamic> _handleBuyResponse(Response response) {
    final code = response.statusCode ?? 0;
    if (code == 200 || code == 201) {
      // Success: backend returned 2xx
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Purchase successful'};
    }

    // 4xx response (DioClient.validateStatus allows < 500 to pass through)
    final data = response.data;
    String message = 'Purchase failed';
    if (data is Map<String, dynamic>) {
      message = (data['message'] ?? data['error'] ?? message).toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }
    throw BuyException(statusCode: code, message: message);
  }

  BuyException _extractBuyError(DioException e) {
    final code = e.response?.statusCode ?? 0;
    String message = 'Purchase failed. Please try again.';
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      message = (data['message'] ?? data['error'] ?? message).toString();
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    }
    return BuyException(statusCode: code, message: message);
  }

  Future<bool> isBookInLibrary(int bookId) async {
    try {
      final response = await dioClient.dio.get('/library', queryParameters: {'pageSize': 50});
      final items = response.data['items'] as List<dynamic>? ?? [];
      return items.any((item) => item['bookId'] == bookId);
    } catch (e) {
      return false;
    }
  }
}

/// Lightweight projection of `ReadingSessionResponse` returned by the
/// progress endpoint. Only carries the fields the reader UI actually
/// reacts to.
class ProgressUpdateResult {
  final int currentPage;
  final int progressPercentage;
  final bool isCompleted;

  /// Tokens awarded by *this* update only (the backend computes them from
  /// the delta minutes the client just submitted).
  final int tokensEarned;

  const ProgressUpdateResult({
    required this.currentPage,
    required this.progressPercentage,
    required this.isCompleted,
    required this.tokensEarned,
  });

  factory ProgressUpdateResult.fromJson(Map<String, dynamic> json) {
    return ProgressUpdateResult(
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      tokensEarned: (json['tokensEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class BuyException implements Exception {
  final int statusCode;
  final String message;
  BuyException({required this.statusCode, required this.message});

  bool get isInsufficientBalance =>
      statusCode == 400 &&
      (message.toLowerCase().contains('insufficient') ||
          message.toLowerCase().contains('balance') ||
          message.toLowerCase().contains('tokens') ||
          message.toLowerCase().contains('funds'));

  bool get isAlreadyOwned =>
      statusCode == 409 ||
      message.toLowerCase().contains('already');

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class RatingException implements Exception {
  final int statusCode;
  final String message;
  RatingException({required this.statusCode, required this.message});

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
