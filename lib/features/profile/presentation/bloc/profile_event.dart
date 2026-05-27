import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

/// Load profile — skips fetch if already loaded (cached).
class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

/// Force re-fetch regardless of current state (e.g. pull-to-refresh).
class RefreshProfileEvent extends ProfileEvent {
  const RefreshProfileEvent();
}

/// Wipe state on logout so the next user doesn't see stale profile data.
class ResetProfileEvent extends ProfileEvent {
  const ResetProfileEvent();
}
