import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/home_response_model.dart';
import '../repositories/home_repository.dart';

class GetHomeUseCase {
  final HomeRepository repository;

  GetHomeUseCase(this.repository);

  Future<Either<Failure, HomeResponse>> call() {
    return repository.getHome();
  }
}
