import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/home_response_model.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeResponse>> getHome();
}
