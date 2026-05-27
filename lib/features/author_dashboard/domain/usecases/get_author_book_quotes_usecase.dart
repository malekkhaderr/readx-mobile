import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/author_quote_model.dart';
import '../repositories/author_dashboard_repository.dart';

class GetAuthorBookQuotesUseCase {
  final AuthorDashboardRepository repository;

  GetAuthorBookQuotesUseCase(this.repository);

  Future<Either<Failure, PaginatedAuthorQuotesResponse>> call(GetAuthorBookQuotesParams params) async {
    return await repository.getBookQuotes(params.bookId, page: params.page, limit: params.limit);
  }
}

class GetAuthorBookQuotesParams extends Equatable {
  final int bookId;
  final int page;
  final int limit;

  const GetAuthorBookQuotesParams({required this.bookId, this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [bookId, page, limit];
}
