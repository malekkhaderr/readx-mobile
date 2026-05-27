import 'package:equatable/equatable.dart';
import '../../data/models/library_book_model.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();
  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<LibraryBook> books;
  final ReadingStatus? activeFilter;
  final int totalCount;

  const LibraryLoaded({
    required this.books,
    this.activeFilter,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [books, activeFilter, totalCount];

  int get wantToReadCount =>
      books.where((b) => b.status == ReadingStatus.wantToRead).length;
  int get readingCount =>
      books.where((b) => b.status == ReadingStatus.currentlyReading).length;
  int get readCount =>
      books.where((b) => b.status == ReadingStatus.read).length;
}

class LibraryError extends LibraryState {
  final String message;
  const LibraryError({required this.message});
  @override
  List<Object?> get props => [message];
}
