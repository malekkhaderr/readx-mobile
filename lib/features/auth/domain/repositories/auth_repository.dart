import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> resetPassword({required String email});
}
