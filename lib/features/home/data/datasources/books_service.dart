import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/book_detail_model.dart';

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
}
