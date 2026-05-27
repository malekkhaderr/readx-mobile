import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/reports_repository.dart';

class SubmitReportUseCase {
  final ReportsRepository repository;

  SubmitReportUseCase(this.repository);

  Future<Either<Failure, void>> call({
    int? reasonId,
    String? customReason,
    String? description,
  }) async {
    return await repository.submitReport(
      reasonId: reasonId,
      customReason: customReason,
      description: description,
    );
  }
}
