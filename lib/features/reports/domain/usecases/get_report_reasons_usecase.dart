import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_reason_entity.dart';
import '../repositories/reports_repository.dart';

class GetReportReasonsUseCase {
  final ReportsRepository repository;

  GetReportReasonsUseCase(this.repository);

  Future<Either<Failure, List<ReportReasonEntity>>> call() async {
    return await repository.getReportReasons();
  }
}
