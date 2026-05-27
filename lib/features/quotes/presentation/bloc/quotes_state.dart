import 'package:equatable/equatable.dart';
import '../../data/datasources/quotes_remote_datasource.dart';
import '../../data/models/quote_model.dart';

abstract class QuotesState extends Equatable {
  const QuotesState();
  @override
  List<Object?> get props => [];
}

class QuotesInitial extends QuotesState {}

// ── Public feed ──
class PublicFeedLoading extends QuotesState {}

class PublicFeedLoaded extends QuotesState {
  final List<QuoteDetails> items;
  final QuotesSort sort;
  final int? bookFilter;
  final int? categoryFilter;

  const PublicFeedLoaded({
    required this.items,
    required this.sort,
    this.bookFilter,
    this.categoryFilter,
  });

  PublicFeedLoaded copyWith({
    List<QuoteDetails>? items,
    QuotesSort? sort,
    int? bookFilter,
    int? categoryFilter,
    bool clearBookFilter = false,
    bool clearCategoryFilter = false,
  }) {
    return PublicFeedLoaded(
      items: items ?? this.items,
      sort: sort ?? this.sort,
      bookFilter: clearBookFilter ? null : (bookFilter ?? this.bookFilter),
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
    );
  }

  bool get hasActiveFilter => bookFilter != null || categoryFilter != null;

  @override
  List<Object?> get props => [items, sort, bookFilter, categoryFilter];
}

class PublicFeedError extends QuotesState {
  final String message;
  const PublicFeedError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── My Quotes ──
class MyQuotesLoading extends QuotesState {}

class MyQuotesLoaded extends QuotesState {
  final List<MyQuote> items;
  const MyQuotesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class MyQuotesError extends QuotesState {
  final String message;
  const MyQuotesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Composite (used so the page can show feed + my quotes side-by-side) ──
class QuotesCombined extends QuotesState {
  final QuotesState feedState; // PublicFeedLoading | Loaded | Error
  final QuotesState myState;   // MyQuotesLoading | Loaded | Error

  const QuotesCombined({required this.feedState, required this.myState});

  QuotesCombined copyWith({QuotesState? feedState, QuotesState? myState}) {
    return QuotesCombined(
      feedState: feedState ?? this.feedState,
      myState: myState ?? this.myState,
    );
  }

  @override
  List<Object?> get props => [feedState, myState];
}
