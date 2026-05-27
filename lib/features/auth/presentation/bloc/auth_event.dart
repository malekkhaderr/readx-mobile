import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final int gender;
  final DateTime birthDate;

  const RegisterEvent({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.gender,
    required this.birthDate,
  });

  @override
  List<Object> get props => [
    firstName,
    lastName,
    email,
    password,
    confirmPassword,
    gender,
    birthDate,
  ];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  final String otpCode;
  final String newPassword;
  final String confirmNewPassword;

  const ResetPasswordEvent({
    required this.email,
    required this.otpCode,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  @override
  List<Object> get props => [email, otpCode, newPassword, confirmNewPassword];
}

class SendOtpEvent extends AuthEvent {
  final String email;
  final int purpose;

  const SendOtpEvent({required this.email, required this.purpose});

  @override
  List<Object> get props => [email, purpose];
}

class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String code;
  final int purpose;

  const VerifyOtpEvent({
    required this.email,
    required this.code,
    required this.purpose,
  });

  @override
  List<Object> get props => [email, code, purpose];
}
