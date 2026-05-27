import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkOneNotificationReadUseCase {
  final NotificationsRepository repository;

  MarkOneNotificationReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId, int notificationId) {
    return repository.markOneAsRead(userId, notificationId);
  }
}
