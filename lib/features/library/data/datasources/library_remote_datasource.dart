import '../../../../core/network/dio_client.dart';
import '../models/library_book_model.dart';

class LibraryRemoteDataSource {
  final DioClient dioClient;

  LibraryRemoteDataSource({required this.dioClient});

  Future<LibraryResponse> getMyLibrary({
    ReadingStatus? status,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (status != null) {
      queryParams['status'] = status.value;
    }

    final response = await dioClient.dio.get(
      '/library',
      queryParameters: queryParams,
    );
    return LibraryResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addToLibrary(int bookId, {ReadingStatus status = ReadingStatus.wantToRead}) async {
    await dioClient.dio.post(
      '/library/$bookId',
      queryParameters: {'status': status.value},
    );
  }

  Future<void> updateStatus(int bookId, ReadingStatus status) async {
    await dioClient.dio.post(
      '/library/$bookId',
      queryParameters: {'status': status.value},
    );
  }

  Future<void> removeFromLibrary(int bookId) async {
    await dioClient.dio.delete('/library/$bookId');
  }
}
