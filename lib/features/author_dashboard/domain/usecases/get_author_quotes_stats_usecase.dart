import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/author_quotes_stats_model.dart';
import '../repositories/author_dashboard_repository.dart';

class GetAuthorQuotesStatsUseCase {
  final AuthorDashboardRepository repository;

  GetAuthorQuotesStatsUseCase(this.repository);

  Future<Either<Failure, AuthorQuotesStatsModel>> call() async {
    return await repository.getQuotesStats();
  }
}
