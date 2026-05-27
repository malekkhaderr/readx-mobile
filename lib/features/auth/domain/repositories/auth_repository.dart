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
    required String confirmPassword,
    required int gender,
    required DateTime birthDate,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> sendOtp({
    required String email,
    required int purpose,
  });

  Future<Either<Failure, void>> verifyOtp({
    required String email,
    required String code,
    required int purpose,
  });

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmNewPassword,
  });
}
