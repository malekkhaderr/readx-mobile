import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetMeUseCase {
  final ProfileRepository repository;

  GetMeUseCase(this.repository);

  Future<Either<Failure, UserProfileEntity>> call() {
    return repository.getMe();
  }
}
