import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return repository.resetPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
  }
}
