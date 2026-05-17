import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationsRepository repository;

  MarkAllNotificationsReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.markAllAsRead(userId);
  }
}
