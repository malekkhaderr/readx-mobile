import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAllAsRead(String userId);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final DioClient dioClient;

  NotificationsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await dioClient.dio
          .get('${ApiConstants.notifications}/user/$userId');

      if (response.statusCode != 200) {
        throw ServerException('Failed to load notifications');
      }

      // Tolerate either a raw array (current backend) or a paged shape
      // (`{items: [...], totalCount: ...}`) — same defensive pattern we use
      // for /quotes/my. If the response is anything else (error envelope,
      // unexpected shape) treat as empty.
      final data = response.data;
      List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        if (data['items'] is List) {
          items = data['items'] as List<dynamic>;
        } else if (data['data'] is List) {
          items = data['data'] as List<dynamic>;
        } else {
          throw ServerException(
              data['message']?.toString() ?? 'Unexpected response shape');
        }
      } else {
        return const [];
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final response = await dioClient.dio.put('${ApiConstants.notifications}/user/$userId/mark-all-read');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Failed to mark notifications as read');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
