import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/author_book_model.dart';
import '../repositories/author_dashboard_repository.dart';

class GetAuthorBooksUseCase {
  final AuthorDashboardRepository repository;

  GetAuthorBooksUseCase(this.repository);

  Future<Either<Failure, List<AuthorBook>>> call() {
    return repository.getBooks();
  }
}
