import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../data/datasources/search_remote_datasource.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  static const _debounce = Duration(milliseconds: 350);
  static const _pageSize = 20;

  final SearchRemoteDataSource dataSource;

  SearchBloc({required this.dataSource}) : super(const SearchState()) {
    on<LoadSearchCategoriesEvent>(_onLoadCategories);
    on<LoadInitialBooksEvent>(_onLoadInitial);
    on<QueryChangedEvent>(
      _onQueryChanged,
      transformer: _debounceTransformer(),
    );
    on<ChangeSearchCategoryEvent>(_onChangeCategory);
    on<LoadMoreSearchResultsEvent>(_onLoadMore);
    on<RetrySearchEvent>(_onRetry);
  }

  /// Drop-everything-but-the-latest debouncer. We use `restartable` semantics
  /// (via stream_transform's debounce) so a fast typist's intermediate
  /// keystrokes don't fan out into multiple in-flight searches.
  EventTransformer<E> _debounceTransformer<E>() {
    return (events, mapper) =>
        events.debounce(_debounce).switchMap(mapper);
  }

  Future<void> _onLoadCategories(
    LoadSearchCategoriesEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (state.categories.isNotEmpty) return;
    final cats = await dataSource.getCategories();
    if (emit.isDone) return;
    emit(state.copyWith(categories: cats));
  }

  Future<void> _onLoadInitial(
    LoadInitialBooksEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (state.results.isNotEmpty || state.isLoading) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _runFetch(
      emit,
      term: state.query.trim(),
      categoryId: state.selectedCategoryId,
    );
  }

  Future<void> _onQueryChanged(
    QueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final raw = event.query;
    final trimmed = raw.trim();

    // Empty query → fall back to browse mode (paged /api/books) so the
    // user keeps seeing the catalogue even with no search term.
    if (trimmed.isEmpty) {
      emit(state.copyWith(
        query: raw,
        isLoading: true,
        tooShortQuery: false,
        clearError: true,
      ));
      await _runFetch(emit, term: '', categoryId: state.selectedCategoryId);
      return;
    }

    // 1-char query → still browse mode (the backend would reject /search,
    // and the user expects "almost typing" to show *something*). Surface
    // the "Type 2+ chars" hint as an inline note so they know the search
    // hasn't kicked in yet.
    if (trimmed.length == 1) {
      emit(state.copyWith(
        query: raw,
        isLoading: true,
        tooShortQuery: true,
        clearError: true,
      ));
      await _runFetch(emit, term: '', categoryId: state.selectedCategoryId);
      return;
    }

    emit(state.copyWith(
      query: raw,
      isLoading: true,
      tooShortQuery: false,
      clearError: true,
    ));

    await _runFetch(emit, term: trimmed, categoryId: state.selectedCategoryId);
  }

  Future<void> _onChangeCategory(
    ChangeSearchCategoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    final trimmedQuery = state.query.trim();
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearSelectedCategory: event.categoryId == null,
      selectedCategoryLabel: event.categoryLabel,
      isLoading: true,
      clearError: true,
    ));
    // Browse mode picks /api/books (which supports categoryId on its own);
    // search mode picks /api/books/search (which requires the term).
    await _runFetch(
      emit,
      term: trimmedQuery.length >= 2 ? trimmedQuery : '',
      categoryId: event.categoryId,
    );
  }

  Future<void> _onLoadMore(
    LoadMoreSearchResultsEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final term = state.query.trim();
      final response = term.length >= 2
          ? await dataSource.search(
              term: term,
              categoryId: state.selectedCategoryId,
              pageNumber: state.pageNumber + 1,
              pageSize: _pageSize,
            )
          : await dataSource.browse(
              categoryId: state.selectedCategoryId,
              pageNumber: state.pageNumber + 1,
              pageSize: _pageSize,
            );
      emit(state.copyWith(
        results: [...state.results, ...response.items],
        totalCount: response.totalCount,
        pageNumber: response.pageNumber,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Could not load more results.',
      ));
    }
  }

  Future<void> _onRetry(
    RetrySearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _runFetch(
      emit,
      term: state.query.trim(),
      categoryId: state.selectedCategoryId,
    );
  }

  /// Routes the fetch to either `/api/books/search` (when `term` is ≥ 2
  /// chars — the backend's hard floor for the search endpoint) or
  /// `/api/books` (for browse / category-only / 1-char queries). Both
  /// return the same paged shape so the bloc state model is unchanged.
  Future<void> _runFetch(
    Emitter<SearchState> emit, {
    required String term,
    int? categoryId,
  }) async {
    try {
      final response = term.length >= 2
          ? await dataSource.search(
              term: term,
              categoryId: categoryId,
              pageNumber: 1,
              pageSize: _pageSize,
            )
          : await dataSource.browse(
              categoryId: categoryId,
              pageNumber: 1,
              pageSize: _pageSize,
            );
      if (emit.isDone) return;
      emit(state.copyWith(
        results: response.items,
        totalCount: response.totalCount,
        pageNumber: response.pageNumber,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Couldn\'t load results. Try again.',
      ));
    }
  }
}
