import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_me_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetMeUseCase getMeUseCase;

  ProfileBloc({required this.getMeUseCase}) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<RefreshProfileEvent>(_onRefreshProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Return cached data — avoid re-fetching on every navigation event
    if (state is ProfileLoaded) return;

    await _fetchProfile(emit);
  }

  Future<void> _onRefreshProfile(
    RefreshProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Always re-fetch (pull-to-refresh)
    await _fetchProfile(emit);
  }

  Future<void> _fetchProfile(Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    final result = await getMeUseCase();
    result.fold(
      (failure) {
        final isUnauthorized = failure is UnauthorizedFailure;
        emit(ProfileError(failure.message, isUnauthorized: isUnauthorized));
      },
      (profile) => emit(ProfileLoaded(profile)),
    );
  }
}
