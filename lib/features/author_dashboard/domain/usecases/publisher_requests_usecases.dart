import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/publisher_request_model.dart';
import '../repositories/author_dashboard_repository.dart';

class GetPublisherRequestsUseCase {
  final AuthorDashboardRepository repository;
  GetPublisherRequestsUseCase(this.repository);

  Future<Either<Failure, List<PublisherRequestModel>>> call() async {
    return await repository.getMyRequests();
  }
}

class SubmitAddBookRequestUseCase {
  final AuthorDashboardRepository repository;
  SubmitAddBookRequestUseCase(this.repository);

  Future<Either<Failure, void>> call(AddBookRequestModel params) async {
    return await repository.submitAddBookRequest(params);
  }
}

class SubmitModifyBookRequestUseCase {
  final AuthorDashboardRepository repository;
  SubmitModifyBookRequestUseCase(this.repository);

  Future<Either<Failure, void>> call(ModifyBookRequestModel params) async {
    return await repository.submitModifyBookRequest(params);
  }
}

class SubmitRemoveBookRequestUseCase {
  final AuthorDashboardRepository repository;
  SubmitRemoveBookRequestUseCase(this.repository);

  Future<Either<Failure, void>> call(RemoveBookRequestModel params) async {
    return await repository.submitRemoveBookRequest(params);
  }
}
