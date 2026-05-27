import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String code,
    required int purpose,
  }) {
    return repository.verifyOtp(email: email, code: code, purpose: purpose);
  }
}
