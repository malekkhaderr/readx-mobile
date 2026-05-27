import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/author_dashboard_model.dart';
import '../../data/models/author_book_model.dart';
import '../../data/models/author_statistics_model.dart';
import '../../data/models/publisher_request_model.dart';
import '../../data/models/author_quotes_stats_model.dart';
import '../../data/models/author_quote_model.dart';

abstract class AuthorDashboardRepository {
  Future<Either<Failure, AuthorDashboardOverview>> getDashboard();
  Future<Either<Failure, List<AuthorBook>>> getBooks();
  Future<Either<Failure, AuthorStatistics>> getStatistics({
    int? bookId,
    int? categoryId,
  });
  Future<Either<Failure, AuthorQuotesStatsModel>> getQuotesStats();
  Future<Either<Failure, PaginatedAuthorQuotesResponse>> getBookQuotes(int bookId, {int page = 1, int limit = 10});

  Future<Either<Failure, List<PublisherRequestModel>>> getMyRequests();
  Future<Either<Failure, void>> submitAddBookRequest(AddBookRequestModel request);
  Future<Either<Failure, void>> submitModifyBookRequest(ModifyBookRequestModel request);
  Future<Either<Failure, void>> submitRemoveBookRequest(RemoveBookRequestModel request);
}
