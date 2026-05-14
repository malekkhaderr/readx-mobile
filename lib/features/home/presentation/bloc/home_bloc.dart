import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_home_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeUseCase getHomeUseCase;

  HomeBloc({required this.getHomeUseCase}) : super(HomeInitial()) {
    on<LoadHomeEvent>(_onLoadHome);
    on<RefreshHomeEvent>(_onRefreshHome);
  }

  Future<void> _onLoadHome(
      LoadHomeEvent event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) return;

    emit(const HomeLoading(isFirstFetch: true));
    final result = await getHomeUseCase();

    result.fold(
      (failure) => emit(HomeError(message: failure.message)),
      (data) => emit(HomeLoaded(data: data)),
    );
  }

  Future<void> _onRefreshHome(
      RefreshHomeEvent event, Emitter<HomeState> emit) async {
    final result = await getHomeUseCase();

    result.fold(
      (failure) => emit(HomeError(message: failure.message)),
      (data) => emit(HomeLoaded(data: data)),
    );
  }
}
