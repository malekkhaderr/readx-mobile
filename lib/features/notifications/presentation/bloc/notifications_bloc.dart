import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.markAllNotificationsReadUseCase,
  }) : super(NotificationsInitial()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkAllNotificationsReadEvent>(_onMarkAllRead);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    final result = await getNotificationsUseCase(event.userId);

    result.fold(
      (failure) => emit(NotificationsError(message: failure.message)),
      (notifications) {
        if (notifications.isEmpty) {
          emit(NotificationsEmpty());
        } else {
          // Sort by date descending (newest first)
          final sorted = List<NotificationEntity>.from(notifications)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          emit(NotificationsLoaded(notifications: sorted));
        }
      },
    );
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // Only process if currently loaded to maintain state locally
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      
      if (currentState.areAllRead) return; // Prevent unnecessary API calls

      // Optimistic update locally
      final updatedNotifications = currentState.notifications.map((n) {
        return NotificationEntity(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();

      emit(NotificationsLoaded(notifications: updatedNotifications));

      // Hit API
      final result = await markAllNotificationsReadUseCase(event.userId);

      result.fold(
        (failure) {
          // If API fails, we could revert to currentState or show an error
          emit(NotificationsError(message: failure.message));
          emit(currentState); // Revert optimistic update
        },
        (_) {
          // Success, already optimistically updated
        },
      );
    }
  }
}
