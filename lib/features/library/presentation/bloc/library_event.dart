import 'package:equatable/equatable.dart';
import '../../data/models/library_book_model.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

class LoadLibraryEvent extends LibraryEvent {
  final ReadingStatus? filterStatus;
  const LoadLibraryEvent({this.filterStatus});
  @override
  List<Object?> get props => [filterStatus];
}

class RefreshLibraryEvent extends LibraryEvent {
  const RefreshLibraryEvent();
}

/// Wipe state on logout so the next user doesn't see the previous user's books.
class ResetLibraryEvent extends LibraryEvent {
  const ResetLibraryEvent();
}

class AddToLibraryEvent extends LibraryEvent {
  final int bookId;
  final ReadingStatus status;
  const AddToLibraryEvent({required this.bookId, this.status = ReadingStatus.wantToRead});
  @override
  List<Object?> get props => [bookId, status];
}

class UpdateBookStatusEvent extends LibraryEvent {
  final int bookId;
  final ReadingStatus newStatus;
  const UpdateBookStatusEvent({required this.bookId, required this.newStatus});
  @override
  List<Object?> get props => [bookId, newStatus];
}

class RemoveFromLibraryEvent extends LibraryEvent {
  final int bookId;
  const RemoveFromLibraryEvent({required this.bookId});
  @override
  List<Object?> get props => [bookId];
}

class ChangeFilterEvent extends LibraryEvent {
  final ReadingStatus? filterStatus;
  const ChangeFilterEvent({this.filterStatus});
  @override
  List<Object?> get props => [filterStatus];
}
