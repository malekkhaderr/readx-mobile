import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_response_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, HomeResponse>> getHome() async {
    try {
      final response = await remoteDataSource.getHome();
      return Right(response);
    } on DioException catch (e) {
      return Left(ServerFailure(
          e.response?.data?['message'] ?? 'Failed to load home data'));
    } catch (e) {
      return Left(const ServerFailure('An unexpected error occurred'));
    }
  }
}
