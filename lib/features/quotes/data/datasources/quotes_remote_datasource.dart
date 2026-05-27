import '../../../../core/network/dio_client.dart';
import '../models/quote_model.dart';

/// Backend `sortBy` keyword. The API expects exactly `"votes"` (orders by
/// upvote count, highest first) or `"date"` (newest first). Anything else
/// silently falls back to date order — that was the bug we previously
/// hit when sending "popular" / "newest".
enum QuotesSort {
  popular('votes'),
  newest('date');

  final String value;
  const QuotesSort(this.value);
}

class QuotesRemoteDataSource {
  final DioClient dioClient;
  QuotesRemoteDataSource({required this.dioClient});

  /// Public feed — `GET /api/quotes` with optional filters/sort/paging.
  Future<QuotesPagedResponse> getPublicQuotes({
    int? bookId,
    int? categoryId,
    DateTime? date,
    QuotesSort sort = QuotesSort.popular,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'sortBy': sort.value,
    };
    if (bookId != null) query['bookId'] = bookId;
    if (categoryId != null) query['categoryId'] = categoryId;
    if (date != null) query['date'] = date.toIso8601String();

    final response = await dioClient.dio.get('/quotes', queryParameters: query);
    return QuotesPagedResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// "My Quotes" — `GET /api/quotes/my`. Returns simpler [MyQuote] objects.
  /// Throws if the response is an error envelope (e.g. 401 unauthorized).
  Future<List<MyQuote>> getMyQuotes() async {
    final response = await dioClient.dio.get('/quotes/my');
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('getMyQuotes failed: HTTP $code');
    }

    final data = response.data;

    // Backend may return either a raw array or a paged shape.
    if (data is List) {
      return data
          .map((e) => MyQuote.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      // If the response looks like an error envelope (no items/data), throw.
      if (data['items'] == null &&
          data['data'] == null &&
          data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      final items = (data['items'] ?? data['data']) as List<dynamic>? ??
          const [];
      return items
          .map((e) => MyQuote.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Save a new highlight — `POST /api/quotes`.
  Future<void> addQuote({
    required int bookId,
    required String content,
    required int pageNumber,
    bool isPublic = true,
  }) async {
    await dioClient.dio.post('/quotes', data: {
      'bookId': bookId,
      'content': content,
      'pageNumber': pageNumber,
      'isPublic': isPublic,
    });
  }

  /// Delete a quote — `DELETE /api/quotes/{id}`.
  Future<void> deleteQuote(int id) async {
    await dioClient.dio.delete('/quotes/$id');
  }

  /// Toggle a vote — `POST /api/quotes/{id}/vote`.
  /// Backend handles the toggle/swap logic itself; the frontend just sends
  /// whichever button the user pressed.
  Future<void> voteQuote(int id, QuoteVote vote) async {
    await dioClient.dio.post(
      '/quotes/$id/vote',
      data: {'voteType': vote.value},
    );
  }
}
