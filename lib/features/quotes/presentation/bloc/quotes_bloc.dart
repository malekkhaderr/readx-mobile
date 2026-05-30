import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/quotes_remote_datasource.dart';
import '../../data/models/quote_model.dart';
import 'quotes_event.dart';
import 'quotes_state.dart';

/// Single bloc that manages BOTH the public feed and the user's personal
/// quotes ("My Quotes"). The page uses tabs to switch between them but they
/// share state so navigating doesn't refetch.
class QuotesBloc extends Bloc<QuotesEvent, QuotesState> {
  final QuotesRemoteDataSource dataSource;

  QuotesSort _currentSort = QuotesSort.popular;
  int? _currentBookFilter;
  int? _currentCategoryFilter;

  QuotesBloc({required this.dataSource}) : super(QuotesInitial()) {
    on<LoadPublicFeedEvent>(_onLoadFeed);
    on<RefreshPublicFeedEvent>(_onRefreshFeed);
    on<ChangeSortEvent>(_onChangeSort);
    on<ChangeBookFilterEvent>(_onChangeBookFilter);
    on<ChangeCategoryFilterEvent>(_onChangeCategoryFilter);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<VoteQuoteEvent>(_onVote);
    on<LoadMyQuotesEvent>(_onLoadMy);
    on<RefreshMyQuotesEvent>(_onRefreshMy);
    on<AddQuoteEvent>(_onAdd);
    on<DeleteQuoteEvent>(_onDelete);
    on<ResetQuotesEvent>((_, emit) {
      _currentSort = QuotesSort.popular;
      _currentBookFilter = null;
      _currentCategoryFilter = null;
      emit(QuotesInitial());
    });
  }

  QuotesCombined _ensureCombined() {
    final s = state;
    if (s is QuotesCombined) return s;
    return QuotesCombined(
      feedState: QuotesInitial(),
      myState: QuotesInitial(),
    );
  }

  Future<void> _onLoadFeed(
      LoadPublicFeedEvent event, Emitter<QuotesState> emit) async {
    final combined = _ensureCombined();
    if (combined.feedState is PublicFeedLoaded &&
        event.sort == _currentSort &&
        event.bookFilter == _currentBookFilter) {
      return; // already loaded
    }
    _currentSort = event.sort;
    _currentBookFilter = event.bookFilter;
    emit(combined.copyWith(feedState: PublicFeedLoading()));
    await _fetchFeed(emit);
  }

  Future<void> _onRefreshFeed(
      RefreshPublicFeedEvent event, Emitter<QuotesState> emit) async {
    await _fetchFeed(emit);
  }

  Future<void> _onChangeSort(
      ChangeSortEvent event, Emitter<QuotesState> emit) async {
    if (event.sort == _currentSort) return;
    _currentSort = event.sort;
    final combined = _ensureCombined();
    emit(combined.copyWith(feedState: PublicFeedLoading()));
    await _fetchFeed(emit);
  }

  Future<void> _onChangeBookFilter(
      ChangeBookFilterEvent event, Emitter<QuotesState> emit) async {
    _currentBookFilter = event.bookId;
    final combined = _ensureCombined();
    emit(combined.copyWith(feedState: PublicFeedLoading()));
    await _fetchFeed(emit);
  }

  Future<void> _onChangeCategoryFilter(
      ChangeCategoryFilterEvent event, Emitter<QuotesState> emit) async {
    _currentCategoryFilter = event.categoryId;
    final combined = _ensureCombined();
    emit(combined.copyWith(feedState: PublicFeedLoading()));
    await _fetchFeed(emit);
  }

  Future<void> _onApplyFilters(
      ApplyFiltersEvent event, Emitter<QuotesState> emit) async {
    _currentBookFilter = event.bookId;
    _currentCategoryFilter = event.categoryId;
    final combined = _ensureCombined();
    emit(combined.copyWith(feedState: PublicFeedLoading()));
    await _fetchFeed(emit);
  }

  Future<void> _fetchFeed(Emitter<QuotesState> emit) async {
    try {
      final paged = await dataSource.getPublicQuotes(
        sort: _currentSort,
        bookId: _currentBookFilter,
        categoryId: _currentCategoryFilter,
      );
      // Read state again *after* the API call so we don't overwrite a
      // myQuotes update that finished while we were fetching.
      final latest = _ensureCombined();
      emit(latest.copyWith(
        feedState: PublicFeedLoaded(
          items: paged.items,
          sort: _currentSort,
          bookFilter: _currentBookFilter,
          categoryFilter: _currentCategoryFilter,
        ),
      ));
    } catch (_) {
      final latest = _ensureCombined();
      emit(latest.copyWith(
        feedState: const PublicFeedError(
            'Could not load quotes. Pull to refresh.'),
      ));
    }
  }

  Future<void> _onVote(VoteQuoteEvent event, Emitter<QuotesState> emit) async {
    final combined = _ensureCombined();
    final feed = combined.feedState;
    if (feed is! PublicFeedLoaded) return;

    // Optimistic update
    final idx = feed.items.indexWhere((q) => q.id == event.quoteId);
    if (idx == -1) return;
    final old = feed.items[idx];
    final tappedUp = event.vote == QuoteVote.upvote;
    int upDelta = 0;
    int downDelta = 0;
    int? newVote;

    if (tappedUp) {
      if (old.hasUpvoted) {
        upDelta = -1;
        newVote = null;
      } else if (old.hasDownvoted) {
        downDelta = -1;
        upDelta = 1;
        newVote = 0;
      } else {
        upDelta = 1;
        newVote = 0;
      }
    } else {
      if (old.hasDownvoted) {
        downDelta = -1;
        newVote = null;
      } else if (old.hasUpvoted) {
        upDelta = -1;
        downDelta = 1;
        newVote = 1;
      } else {
        downDelta = 1;
        newVote = 1;
      }
    }

    final updated = old.copyWith(
      upvotes: (old.upvotes + upDelta).clamp(0, 1 << 30),
      downvotes: (old.downvotes + downDelta).clamp(0, 1 << 30),
      currentUserVote: newVote,
      clearVote: newVote == null,
    );
    final newItems = List<QuoteDetails>.from(feed.items);
    newItems[idx] = updated;

    // If we are sorted by popularity, re-order so the user immediately sees
    // the quote climb (or fall) the leaderboard after their vote.
    if (feed.sort == QuotesSort.popular) {
      newItems.sort((a, b) {
        final scoreA = a.upvotes - a.downvotes;
        final scoreB = b.upvotes - b.downvotes;
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    emit(combined.copyWith(feedState: feed.copyWith(items: newItems)));

    try {
      await dataSource.voteQuote(event.quoteId, event.vote);
    } catch (_) {
      // revert on failure — restore original list (also restores order)
      emit(combined.copyWith(feedState: feed.copyWith(items: feed.items)));
    }
  }

  Future<void> _onLoadMy(
      LoadMyQuotesEvent event, Emitter<QuotesState> emit) async {
    final combined = _ensureCombined();
    if (combined.myState is MyQuotesLoaded) return;
    emit(combined.copyWith(myState: MyQuotesLoading()));
    await _fetchMy(emit);
  }

  Future<void> _onRefreshMy(
      RefreshMyQuotesEvent event, Emitter<QuotesState> emit) async {
    await _fetchMy(emit);
  }

  Future<void> _fetchMy(Emitter<QuotesState> emit) async {
    try {
      final items = await dataSource.getMyQuotes();
      final latest = _ensureCombined();
      emit(latest.copyWith(myState: MyQuotesLoaded(items)));
    } catch (_) {
      final latest = _ensureCombined();
      emit(latest.copyWith(
        myState: const MyQuotesError('Could not load your quotes.'),
      ));
    }
  }

  Future<void> _onAdd(AddQuoteEvent event, Emitter<QuotesState> emit) async {
    Object? failure;
    try {
      await dataSource.addQuote(
        bookId: event.bookId,
        content: event.content,
        pageNumber: event.pageNumber,
        isPublic: event.isPublic,
      );
    } catch (e) {
      failure = e;
    }

    // Always refresh both views so the UI reflects the latest server state,
    // whether the add succeeded or not. _fetchMy / _fetchFeed each emit a
    // new state at the end, which is what the Add Quote page listens for.
    await _fetchMy(emit);
    if (event.isPublic) await _fetchFeed(emit);

    if (failure != null) {
      // Bubble up via an error state on whichever slice is currently shown.
      final latest = _ensureCombined();
      emit(latest.copyWith(
        myState: const MyQuotesError('Could not save the quote.'),
      ));
    }
  }

  Future<void> _onDelete(
      DeleteQuoteEvent event, Emitter<QuotesState> emit) async {
    final combined = _ensureCombined();
    final my = combined.myState;
    if (my is MyQuotesLoaded) {
      final filtered =
          my.items.where((q) => q.id != event.quoteId).toList(growable: false);
      emit(combined.copyWith(myState: MyQuotesLoaded(filtered)));
    }
    final feed = combined.feedState;
    if (feed is PublicFeedLoaded) {
      final filtered =
          feed.items.where((q) => q.id != event.quoteId).toList(growable: false);
      emit(combined.copyWith(feedState: feed.copyWith(items: filtered)));
    }
    try {
      await dataSource.deleteQuote(event.quoteId);
      // Success — re-fetch to sync with server (the optimistic removal
      // above already shows the right UI, this just confirms it).
      await _fetchMy(emit);
    } catch (e) {
      // Delete failed (auth, ownership, network) — re-fetch to restore
      // the quote that was optimistically removed.
      debugPrint('Delete quote ${event.quoteId} failed: $e');
      await _fetchMy(emit);
      await _fetchFeed(emit);
    }
  }
}
