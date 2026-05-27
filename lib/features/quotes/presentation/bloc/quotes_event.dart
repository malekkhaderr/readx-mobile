import 'package:equatable/equatable.dart';
import '../../data/datasources/quotes_remote_datasource.dart';
import '../../data/models/quote_model.dart';

abstract class QuotesEvent extends Equatable {
  const QuotesEvent();
  @override
  List<Object?> get props => [];
}

// ── Public feed ──
class LoadPublicFeedEvent extends QuotesEvent {
  final QuotesSort sort;
  final int? bookFilter;
  const LoadPublicFeedEvent({
    this.sort = QuotesSort.popular,
    this.bookFilter,
  });
  @override
  List<Object?> get props => [sort, bookFilter];
}

class RefreshPublicFeedEvent extends QuotesEvent {
  const RefreshPublicFeedEvent();
}

class ChangeSortEvent extends QuotesEvent {
  final QuotesSort sort;
  const ChangeSortEvent(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ChangeBookFilterEvent extends QuotesEvent {
  final int? bookId;
  const ChangeBookFilterEvent(this.bookId);
  @override
  List<Object?> get props => [bookId];
}

/// Change the active category filter (or pass null to clear it).
/// Sent as `categoryId` query param on the next /api/quotes fetch.
class ChangeCategoryFilterEvent extends QuotesEvent {
  final int? categoryId;
  const ChangeCategoryFilterEvent(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

/// Apply both filters in a single round-trip — used by the filter sheet
/// when the user picks a book AND a category before pressing Apply.
class ApplyFiltersEvent extends QuotesEvent {
  final int? bookId;
  final int? categoryId;
  const ApplyFiltersEvent({this.bookId, this.categoryId});
  @override
  List<Object?> get props => [bookId, categoryId];
}

class VoteQuoteEvent extends QuotesEvent {
  final int quoteId;
  final QuoteVote vote;
  const VoteQuoteEvent({required this.quoteId, required this.vote});
  @override
  List<Object?> get props => [quoteId, vote];
}

// ── My Quotes ──
class LoadMyQuotesEvent extends QuotesEvent {
  const LoadMyQuotesEvent();
}

class RefreshMyQuotesEvent extends QuotesEvent {
  const RefreshMyQuotesEvent();
}

class AddQuoteEvent extends QuotesEvent {
  final int bookId;
  final String content;
  final int pageNumber;
  final bool isPublic;
  const AddQuoteEvent({
    required this.bookId,
    required this.content,
    required this.pageNumber,
    this.isPublic = true,
  });
  @override
  List<Object?> get props => [bookId, content, pageNumber, isPublic];
}

class DeleteQuoteEvent extends QuotesEvent {
  final int quoteId;
  const DeleteQuoteEvent(this.quoteId);
  @override
  List<Object?> get props => [quoteId];
}

/// Wipe state on logout so the next user starts clean.
class ResetQuotesEvent extends QuotesEvent {
  const ResetQuotesEvent();
}
