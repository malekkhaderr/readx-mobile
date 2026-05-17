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
      final response = await dioClient.dio.get('${ApiConstants.notifications}/user/$userId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load notifications');
      }
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
