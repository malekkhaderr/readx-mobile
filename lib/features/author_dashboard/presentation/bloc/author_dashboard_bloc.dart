import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/author_dashboard_model.dart';
import '../../data/models/author_book_model.dart';
import '../../data/models/author_statistics_model.dart';
import '../../domain/usecases/get_author_dashboard_usecase.dart';
import '../../domain/usecases/get_author_books_usecase.dart';
import '../../domain/usecases/get_author_statistics_usecase.dart';
import '../../domain/usecases/publisher_requests_usecases.dart';
import '../../domain/usecases/get_author_quotes_stats_usecase.dart';
import '../../data/models/publisher_request_model.dart';
import '../../data/models/author_quotes_stats_model.dart';
import '../../domain/usecases/get_author_book_quotes_usecase.dart';
// Events
abstract class AuthorDashboardEvent extends Equatable {
  const AuthorDashboardEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadAuthorDashboardEvent extends AuthorDashboardEvent {}

class RefreshAuthorDashboardEvent extends AuthorDashboardEvent {}

class LoadAuthorStatisticsEvent extends AuthorDashboardEvent {
  final int? bookId;
  final int? categoryId;

  const LoadAuthorStatisticsEvent({this.bookId, this.categoryId});

  @override
  List<Object?> get props => [bookId, categoryId];
}

class LoadPublisherRequestsEvent extends AuthorDashboardEvent {}

class SubmitAddBookRequestEvent extends AuthorDashboardEvent {
  final AddBookRequestModel request;
  const SubmitAddBookRequestEvent(this.request);
  @override
  List<Object?> get props => [request];
}

class SubmitModifyBookRequestEvent extends AuthorDashboardEvent {
  final ModifyBookRequestModel request;
  const SubmitModifyBookRequestEvent(this.request);
  @override
  List<Object?> get props => [request];
}

class SubmitRemoveBookRequestEvent extends AuthorDashboardEvent {
  final RemoveBookRequestModel request;
  const SubmitRemoveBookRequestEvent(this.request);
  @override
  List<Object?> get props => [request];
}

// States
abstract class AuthorDashboardState extends Equatable {
  const AuthorDashboardState();
  
  @override
  List<Object?> get props => [];
}

class AuthorDashboardInitial extends AuthorDashboardState {}

class AuthorDashboardLoading extends AuthorDashboardState {}

class AuthorDashboardLoaded extends AuthorDashboardState {
  final AuthorDashboardOverview dashboard;
  final List<AuthorBook> books;
  final AuthorQuotesStatsModel? quotesStats;

  const AuthorDashboardLoaded({
    required this.dashboard,
    required this.books,
    this.quotesStats,
  });

  @override
  List<Object?> get props => [dashboard, books, quotesStats];
}

class AuthorDashboardError extends AuthorDashboardState {
  final String message;
  const AuthorDashboardError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthorStatisticsLoading extends AuthorDashboardState {}

class AuthorStatisticsLoaded extends AuthorDashboardState {
  final AuthorStatistics statistics;
  final AuthorQuotesStatsModel? quotesStats;
  final AuthorDashboardOverview? dashboard;
  final List<AuthorBook>? books;

  const AuthorStatisticsLoaded({
    required this.statistics,
    this.quotesStats,
    this.dashboard,
    this.books,
  });

  @override
  List<Object?> get props => [statistics, quotesStats, dashboard, books];
}

class AuthorStatisticsError extends AuthorDashboardState {
  final String message;
  const AuthorStatisticsError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class PublisherRequestsLoading extends AuthorDashboardState {}

class PublisherRequestsLoaded extends AuthorDashboardState {
  final List<PublisherRequestModel> requests;
  const PublisherRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class PublisherRequestSubmitting extends AuthorDashboardState {}

class PublisherRequestSubmitSuccess extends AuthorDashboardState {
  final String message;
  const PublisherRequestSubmitSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthorDashboardBloc extends Bloc<AuthorDashboardEvent, AuthorDashboardState> {
  final GetAuthorDashboardUseCase getAuthorDashboardUseCase;
  final GetAuthorBooksUseCase getAuthorBooksUseCase;
  final GetAuthorStatisticsUseCase getAuthorStatisticsUseCase;
  final GetPublisherRequestsUseCase getPublisherRequestsUseCase;
  final SubmitAddBookRequestUseCase submitAddBookRequestUseCase;
  final SubmitModifyBookRequestUseCase submitModifyBookRequestUseCase;
  final SubmitRemoveBookRequestUseCase submitRemoveBookRequestUseCase;
  final GetAuthorQuotesStatsUseCase getAuthorQuotesStatsUseCase;
  final GetAuthorBookQuotesUseCase getAuthorBookQuotesUseCase;

  AuthorDashboardOverview? _cachedDashboard;
  List<AuthorBook>? _cachedBooks;
  List<PublisherRequestModel>? _cachedRequests;
  AuthorStatistics? _cachedStatistics;
  AuthorQuotesStatsModel? _cachedQuotesStats;

  List<AuthorBook>? get cachedBooks => _cachedBooks;
  AuthorDashboardOverview? get cachedDashboard => _cachedDashboard;
  List<PublisherRequestModel>? get cachedRequests => _cachedRequests;
  AuthorStatistics? get cachedStatistics => _cachedStatistics;
  AuthorQuotesStatsModel? get cachedQuotesStats => _cachedQuotesStats;

  AuthorDashboardBloc({
    required this.getAuthorDashboardUseCase,
    required this.getAuthorBooksUseCase,
    required this.getAuthorStatisticsUseCase,
    required this.getPublisherRequestsUseCase,
    required this.submitAddBookRequestUseCase,
    required this.submitModifyBookRequestUseCase,
    required this.submitRemoveBookRequestUseCase,
    required this.getAuthorQuotesStatsUseCase,
    required this.getAuthorBookQuotesUseCase,
  }) : super(AuthorDashboardInitial()) {
    on<LoadAuthorDashboardEvent>(_onLoadDashboard);
    on<RefreshAuthorDashboardEvent>(_onRefreshDashboard);
    on<LoadAuthorStatisticsEvent>(_onLoadStatistics);
    on<LoadPublisherRequestsEvent>(_onLoadPublisherRequests);
    on<SubmitAddBookRequestEvent>(_onSubmitAddBook);
    on<SubmitModifyBookRequestEvent>(_onSubmitModifyBook);
    on<SubmitRemoveBookRequestEvent>(_onSubmitRemoveBook);
  }

  Future<void> _onLoadDashboard(
    LoadAuthorDashboardEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    if (_cachedDashboard != null && _cachedBooks != null) {
      emit(AuthorDashboardLoaded(
        dashboard: _cachedDashboard!,
        books: _cachedBooks!,
        quotesStats: _cachedQuotesStats,
      ));
      return;
    }
    
    emit(AuthorDashboardLoading());
    await _fetchDashboardData(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshAuthorDashboardEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    emit(AuthorDashboardLoading());
    await _fetchDashboardData(emit);
  }

  Future<void> _fetchDashboardData(Emitter<AuthorDashboardState> emit) async {
    final dashboardResult = await getAuthorDashboardUseCase();
    final booksResult = await getAuthorBooksUseCase();
    final quotesResult = await getAuthorQuotesStatsUseCase();

    dashboardResult.fold(
      (failure) => emit(AuthorDashboardError(failure.message)),
      (dashboard) {
        _cachedDashboard = dashboard;
        booksResult.fold(
          (failure) => emit(AuthorDashboardError(failure.message)),
          (books) {
            _cachedBooks = books;
            quotesResult.fold(
              (failure) {
                emit(AuthorDashboardLoaded(
                  dashboard: dashboard,
                  books: books,
                  quotesStats: null,
                ));
              },
              (quotes) {
                _cachedQuotesStats = quotes;
                emit(AuthorDashboardLoaded(
                  dashboard: dashboard,
                  books: books,
                  quotesStats: quotes,
                ));
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onLoadStatistics(
    LoadAuthorStatisticsEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    emit(AuthorStatisticsLoading());
    
    final result = await getAuthorStatisticsUseCase(
      bookId: event.bookId,
      categoryId: event.categoryId,
    );

    // Only fetch general author quotes stats if we are not filtering by specific book/category
    // (though in reality we can just fetch it anyway and display what we can)
    final quotesResult = await getAuthorQuotesStatsUseCase();

    result.fold(
      (failure) => emit(AuthorStatisticsError(failure.message)),
      (statistics) {
        _cachedStatistics = statistics;
        
        quotesResult.fold(
          (failure) {
            // we can just ignore quote stats failure or log it, but continue emitting statistics
            emit(AuthorStatisticsLoaded(
              statistics: statistics,
              quotesStats: _cachedQuotesStats,
              dashboard: _cachedDashboard,
              books: _cachedBooks,
            ));
          },
          (quotesStats) {
            _cachedQuotesStats = quotesStats;
            emit(AuthorStatisticsLoaded(
              statistics: statistics,
              quotesStats: quotesStats,
              dashboard: _cachedDashboard,
              books: _cachedBooks,
            ));
          }
        );
      },
    );
  }

  Future<void> _onLoadPublisherRequests(
    LoadPublisherRequestsEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    emit(PublisherRequestsLoading());
    final result = await getPublisherRequestsUseCase();
    result.fold(
      (failure) => emit(AuthorDashboardError(failure.message)),
      (requests) {
        _cachedRequests = requests;
        emit(PublisherRequestsLoaded(requests));
      },
    );
  }

  Future<void> _onSubmitAddBook(
    SubmitAddBookRequestEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    emit(PublisherRequestSubmitting());
    final result = await submitAddBookRequestUseCase(event.request);
    result.fold(
      (failure) => emit(AuthorDashboardError(failure.message)),
      (_) {
        emit(const PublisherRequestSubmitSuccess('Add book request submitted successfully.'));
        add(LoadPublisherRequestsEvent());
      },
    );
  }

  Future<void> _onSubmitModifyBook(
    SubmitModifyBookRequestEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    emit(PublisherRequestSubmitting());
    final result = await submitModifyBookRequestUseCase(event.request);
    result.fold(
      (failure) => emit(AuthorDashboardError(failure.message)),
      (_) {
        emit(const PublisherRequestSubmitSuccess('Modify book request submitted successfully.'));
        add(LoadPublisherRequestsEvent());
      },
    );
  }

  Future<void> _onSubmitRemoveBook(
    SubmitRemoveBookRequestEvent event,
    Emitter<AuthorDashboardState> emit,
  ) async {
    emit(PublisherRequestSubmitting());
    final result = await submitRemoveBookRequestUseCase(event.request);
    result.fold(
      (failure) => emit(AuthorDashboardError(failure.message)),
      (_) {
        emit(const PublisherRequestSubmitSuccess('Remove book request submitted successfully.'));
        add(LoadPublisherRequestsEvent());
      },
    );
  }
}
