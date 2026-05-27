import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class GetMyReportsUseCase {
  final ReportsRepository repository;

  GetMyReportsUseCase(this.repository);

  Future<Either<Failure, List<ReportEntity>>> call() async {
    return await repository.getMyReports();
  }
}
