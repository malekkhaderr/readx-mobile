import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../entities/report_reason_entity.dart';

abstract class ReportsRepository {
  Future<Either<Failure, List<ReportReasonEntity>>> getReportReasons();
  Future<Either<Failure, List<ReportEntity>>> getMyReports();
  Future<Either<Failure, void>> submitReport({
    required int reasonId,
    String? customReason,
    String? description,
  });
}
