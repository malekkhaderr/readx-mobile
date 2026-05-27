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

  Future<void> _onQueryChanged(
    QueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final raw = event.query;
    final trimmed = raw.trim();

    // Empty query → reset to the pre-search hero. Backend rejects an empty
    // SearchTerm with a 400 (model validation) so we never call it.
    if (trimmed.isEmpty) {
      emit(state.copyWith(
        query: raw,
        results: const [],
        totalCount: 0,
        pageNumber: 1,
        hasMore: false,
        isLoading: false,
        tooShortQuery: false,
        clearError: true,
      ));
      return;
    }

    // 1-char query → soft-block: don't hit the server (would be a 400),
    // but tell the UI to show a "type 2+ chars" hint.
    if (trimmed.length == 1) {
      emit(state.copyWith(
        query: raw,
        results: const [],
        totalCount: 0,
        pageNumber: 1,
        hasMore: false,
        isLoading: false,
        tooShortQuery: true,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(
      query: raw,
      isLoading: true,
      tooShortQuery: false,
      clearError: true,
    ));

    await _runSearch(emit, term: trimmed, categoryId: state.selectedCategoryId);
  }

  Future<void> _onChangeCategory(
    ChangeSearchCategoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    final trimmedQuery = state.query.trim();
    // The backend's /search endpoint requires a SearchTerm of at least 2
    // characters; selecting a category alone isn't enough. Stage the chip
    // in state so the user sees their pick is active, but defer the
    // actual query until they've typed something.
    if (trimmedQuery.length < 2) {
      emit(state.copyWith(
        selectedCategoryId: event.categoryId,
        clearSelectedCategory: event.categoryId == null,
        selectedCategoryLabel: event.categoryLabel,
        results: const [],
        totalCount: 0,
        pageNumber: 1,
        hasMore: false,
        isLoading: false,
        tooShortQuery: trimmedQuery.length == 1,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearSelectedCategory: event.categoryId == null,
      selectedCategoryLabel: event.categoryLabel,
      isLoading: true,
      clearError: true,
    ));
    await _runSearch(
      emit,
      term: trimmedQuery,
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
      final response = await dataSource.search(
        term: state.query.trim(),
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
    await _runSearch(
      emit,
      term: state.query.trim(),
      categoryId: state.selectedCategoryId,
    );
  }

  Future<void> _runSearch(
    Emitter<SearchState> emit, {
    required String term,
    int? categoryId,
  }) async {
    try {
      final response = await dataSource.search(
        term: term,
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
