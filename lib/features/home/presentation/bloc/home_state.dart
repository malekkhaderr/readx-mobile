import 'package:equatable/equatable.dart';
import '../../data/models/home_response_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {
  final bool isFirstFetch;

  const HomeLoading({this.isFirstFetch = false});

  @override
  List<Object?> get props => [isFirstFetch];
}

class HomeLoaded extends HomeState {
  final HomeResponse data;

  const HomeLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
