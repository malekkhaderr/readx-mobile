import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => const [];
}

/// One-time call on bloc creation: pulls /api/categories so the filter
/// chips show every active category, not just the ones home/page returned.
class LoadSearchCategoriesEvent extends SearchEvent {
  const LoadSearchCategoriesEvent();
}

/// Initial browse fetch when the user opens the Search tab without any
/// query — pulls the paged list from /api/books so the screen is never
/// empty. Also used after the user clears the search field.
class LoadInitialBooksEvent extends SearchEvent {
  const LoadInitialBooksEvent();
}

/// Fired by the SearchPage every time the user types. The bloc is
/// responsible for debouncing — handlers don't run for every keystroke,
/// only after the user has paused typing.
class QueryChangedEvent extends SearchEvent {
  final String query;
  const QueryChangedEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// User tapped a category chip. `categoryId == null` means "All".
class ChangeSearchCategoryEvent extends SearchEvent {
  final int? categoryId;
  final String categoryLabel;
  const ChangeSearchCategoryEvent({
    required this.categoryId,
    required this.categoryLabel,
  });

  @override
  List<Object?> get props => [categoryId, categoryLabel];
}

/// User scrolled to the bottom of the result grid. Fetches the next page
/// and appends to the existing result list.
class LoadMoreSearchResultsEvent extends SearchEvent {
  const LoadMoreSearchResultsEvent();
}

/// User tapped Retry after an error.
class RetrySearchEvent extends SearchEvent {
  const RetrySearchEvent();
}
