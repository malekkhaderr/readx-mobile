import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/author_statistics_model.dart';
import '../repositories/author_dashboard_repository.dart';

class GetAuthorStatisticsUseCase {
  final AuthorDashboardRepository repository;

  GetAuthorStatisticsUseCase(this.repository);

  Future<Either<Failure, AuthorStatistics>> call({
    int? bookId,
    int? categoryId,
  }) {
    return repository.getStatistics(bookId: bookId, categoryId: categoryId);
  }
}
