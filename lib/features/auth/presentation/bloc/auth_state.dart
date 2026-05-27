import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthRegistered extends AuthState {
  final UserEntity user;
  const AuthRegistered(this.user);

  @override
  List<Object> get props => [user];
}

/// Forgot-password OTP email was dispatched.
class ForgotPasswordSent extends AuthState {
  final String email;
  const ForgotPasswordSent(this.email);

  @override
  List<Object> get props => [email];
}

/// Password was successfully reset; user should head back to /login.
class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

/// An OTP was (re)sent for the email + purpose.
class OtpSent extends AuthState {
  final String email;
  final int purpose;
  const OtpSent({required this.email, required this.purpose});

  @override
  List<Object> get props => [email, purpose];
}

/// An OTP code was successfully verified.
class OtpVerified extends AuthState {
  final String email;
  final int purpose;
  const OtpVerified({required this.email, required this.purpose});

  @override
  List<Object> get props => [email, purpose];
}
