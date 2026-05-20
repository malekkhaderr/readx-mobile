import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/book_detail_model.dart';
import '../models/book_comment_model.dart';

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
      await dioClient.dio.put(
        '${ApiConstants.books}/$bookId/comments/$commentId',
        data: {'body': body},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(int bookId, int commentId) async {
    try {
      await dioClient.dio.delete('${ApiConstants.books}/$bookId/comments/$commentId');
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
}
