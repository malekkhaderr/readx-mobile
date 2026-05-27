import 'package:equatable/equatable.dart';
import '../../../home/data/models/home_response_model.dart';
import '../../data/models/search_models.dart';

class SearchState extends Equatable {
  /// Active query as the user typed it (NOT the trimmed/sent term).
  final String query;

  /// Selected category id (null = "All").
  final int? selectedCategoryId;
  final String selectedCategoryLabel;

  /// All categories available for the chip strip.
  final List<SearchCategory> categories;

  /// Books returned by the most recent search (already paged-merged).
  final List<BookCard> results;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final bool hasMore;

  /// Search request lifecycle.
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Soft validation: when the user has typed exactly 1 character we don't
  /// hit the server (the backend would 400) but we DO want the UI to
  /// communicate "type at least 2 characters" instead of leaving the last
  /// stale results visible.
  final bool tooShortQuery;

  const SearchState({
    this.query = '',
    this.selectedCategoryId,
    this.selectedCategoryLabel = 'All',
    this.categories = const [],
    this.results = const [],
    this.totalCount = 0,
    this.pageNumber = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.tooShortQuery = false,
  });

  SearchState copyWith({
    String? query,
    int? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? selectedCategoryLabel,
    List<SearchCategory>? categories,
    List<BookCard>? results,
    int? totalCount,
    int? pageNumber,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    bool? tooShortQuery,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedCategoryLabel:
          selectedCategoryLabel ?? this.selectedCategoryLabel,
      categories: categories ?? this.categories,
      results: results ?? this.results,
      totalCount: totalCount ?? this.totalCount,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      tooShortQuery: tooShortQuery ?? this.tooShortQuery,
    );
  }

  @override
  List<Object?> get props => [
        query,
        selectedCategoryId,
        selectedCategoryLabel,
        categories,
        results,
        totalCount,
        pageNumber,
        pageSize,
        hasMore,
        isLoading,
        isLoadingMore,
        errorMessage,
        tooShortQuery,
      ];
}
