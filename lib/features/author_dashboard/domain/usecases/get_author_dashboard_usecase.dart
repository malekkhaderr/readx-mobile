import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/author_dashboard_model.dart';
import '../repositories/author_dashboard_repository.dart';

class GetAuthorDashboardUseCase {
  final AuthorDashboardRepository repository;

  GetAuthorDashboardUseCase(this.repository);

  Future<Either<Failure, AuthorDashboardOverview>> call() {
    return repository.getDashboard();
  }
}
