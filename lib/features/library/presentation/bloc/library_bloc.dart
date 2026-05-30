import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../data/datasources/library_remote_datasource.dart';
import '../../data/models/library_book_model.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRemoteDataSource dataSource;
  ReadingStatus? _currentFilter;

  LibraryBloc({required this.dataSource}) : super(LibraryInitial()) {
    on<LoadLibraryEvent>(_onLoad);
    on<RefreshLibraryEvent>(_onRefresh);
    on<AddToLibraryEvent>(_onAdd);
    on<UpdateBookStatusEvent>(_onUpdateStatus);
    on<RemoveFromLibraryEvent>(_onRemove);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<ResetLibraryEvent>((_, emit) {
      _currentFilter = null;
      emit(LibraryInitial());
    });
  }

  Future<void> _onLoad(LoadLibraryEvent event, Emitter<LibraryState> emit) async {
    if (state is LibraryLoaded) return;
    emit(LibraryLoading());
    await _fetchLibrary(emit);
  }

  Future<void> _onRefresh(RefreshLibraryEvent event, Emitter<LibraryState> emit) async {
    await _fetchLibrary(emit);
  }

  Future<void> _onChangeFilter(ChangeFilterEvent event, Emitter<LibraryState> emit) async {
    _currentFilter = event.filterStatus;
    emit(LibraryLoading());
    await _fetchLibrary(emit);
  }

  Future<void> _onAdd(AddToLibraryEvent event, Emitter<LibraryState> emit) async {
    try {
      await dataSource.addToLibrary(event.bookId, status: event.status);
      await _fetchLibrary(emit);
    } catch (e) {
      emit(LibraryError(message: 'Failed to add book to library'));
      await _fetchLibrary(emit);
    }
  }

  Future<void> _onUpdateStatus(UpdateBookStatusEvent event, Emitter<LibraryState> emit) async {
    try {
      await dataSource.updateStatus(event.bookId, event.newStatus);
      await _fetchLibrary(emit);
      // Refresh the profile on any status change so the completed books
      // section stays in sync (adding to or removing from "Read").
      try {
        sl<ProfileBloc>().add(const RefreshProfileEvent());
      } catch (_) {}
    } catch (e) {
      emit(LibraryError(message: 'Failed to update status'));
      await _fetchLibrary(emit);
    }
  }

  Future<void> _onRemove(RemoveFromLibraryEvent event, Emitter<LibraryState> emit) async {
    try {
      await dataSource.removeFromLibrary(event.bookId);
      await _fetchLibrary(emit);
    } catch (e) {
      emit(LibraryError(message: 'Failed to remove book'));
      await _fetchLibrary(emit);
    }
  }

  Future<void> _fetchLibrary(Emitter<LibraryState> emit) async {
    try {
      final response = await dataSource.getMyLibrary(
        status: _currentFilter,
        pageNumber: 1,
        pageSize: 50,
      );
      emit(LibraryLoaded(
        books: response.items,
        activeFilter: _currentFilter,
        totalCount: response.totalCount,
      ));
    } catch (e) {
      emit(LibraryError(message: 'Failed to load library. Please try again.'));
    }
  }
}
