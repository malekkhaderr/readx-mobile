import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required int purpose,
  }) {
    return repository.sendOtp(email: email, purpose: purpose);
  }
}
