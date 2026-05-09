import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserProfileEntity profile;
  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  final bool isUnauthorized;

  const ProfileError(this.message, {this.isUnauthorized = false});

  @override
  List<Object?> get props => [message, isUnauthorized];
}
