import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final int id;
  final int type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, title, message, isRead, createdAt];
}
