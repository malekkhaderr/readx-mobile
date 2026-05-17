import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class FetchNotificationsEvent extends NotificationsEvent {
  final String userId;

  const FetchNotificationsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class MarkAllNotificationsReadEvent extends NotificationsEvent {
  final String userId;

  const MarkAllNotificationsReadEvent(this.userId);

  @override
  List<Object> get props => [userId];
}
