import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/search_models.dart';

class SearchRemoteDataSource {
  final DioClient dioClient;

  SearchRemoteDataSource({required this.dioClient});

  /// Calls `GET /api/books/search`. The backend rejects search terms of
  /// length 1 with a 400 ValidationException, so callers SHOULD pre-guard;
  /// we surface a friendly message if it slips through. Empty strings are
  /// fine and return the full unfiltered page.
  Future<SearchBooksResponse> search({
    required String term,
    int? categoryId,
    int? languageId,
    double? minimumRating,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'searchTerm': term,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (categoryId != null) query['categoryId'] = categoryId;
    if (languageId != null) query['languageId'] = languageId;
    if (minimumRating != null) query['minimumRating'] = minimumRating;

    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.books}/search',
        queryParameters: query,
      );
      // DioClient.validateStatus < 500 lets 4xx through — must inspect.
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300 && response.data is Map<String, dynamic>) {
        return SearchBooksResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerException(_extractMessage(response.data) ?? 'Search failed.');
    } on DioException catch (e) {
      throw ServerException(
        _extractMessage(e.response?.data) ??
            (e.message ?? 'Search request failed.'),
      );
    }
  }

  /// Pulls the full active-category list so the chip strip isn't limited
  /// to the categories the home page happened to return.
  Future<List<SearchCategory>> getCategories() async {
    try {
      final response = await dioClient.dio.get('/categories');
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(SearchCategory.fromJson)
            .where((c) => c.name.isNotEmpty)
            .toList();
      }
      return const [];
    } on DioException {
      // Categories failing isn't fatal — the page still works without
      // chips, so fall back to an empty list and let the bloc render
      // results without the filter strip.
      return const [];
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final raw = data['message'] ?? data['Message'];
      if (raw is String && raw.isNotEmpty) return raw;
    }
    return null;
  }
}
