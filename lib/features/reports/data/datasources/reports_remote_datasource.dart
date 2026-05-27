import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/report_model.dart';
import '../models/report_reason_model.dart';

abstract class ReportsRemoteDataSource {
  Future<List<ReportReasonModel>> getReportReasons();
  Future<List<ReportModel>> getMyReports();
  Future<void> submitReport({
    required int reasonId,
    String? customReason,
    String? description,
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final DioClient dioClient;

  ReportsRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ReportReasonModel>> getReportReasons() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.reportsReasons);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReportReasonModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load report reasons');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ReportModel>> getMyReports() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.reportsMy);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReportModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load my reports');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> submitReport({
    required int reasonId,
    String? customReason,
    String? description,
  }) async {
    try {
      final data = {
        'reasonId': reasonId,
        if (customReason != null && customReason.isNotEmpty)
          'customReason': customReason,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await dioClient.dio.post(
        ApiConstants.reports,
        data: data,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Failed to submit report');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
