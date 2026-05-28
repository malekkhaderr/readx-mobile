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
    on<ResetProfileEvent>((_, emit) => emit(const ProfileInitial()));
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
    // Do NOT emit ProfileLoading here — it causes a widget tree teardown that
    // races with Theme InheritedWidget deactivation when the bottom sheet
    // keyboard dismisses, triggering '_dependents.isEmpty' assertion.
    // Instead, directly emit the new ProfileLoaded so BlocBuilder does an
    // in-place update (same widget type) rather than a type-swap deactivation.
    try {
      final result = await getMeUseCase();
      result.fold(
        (failure) {
          // Keep old profile data on failure — never crash the UI
        },
        (profile) => emit(ProfileLoaded(profile)),
      );
    } catch (_) {}
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
