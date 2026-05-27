/// Carries the state needed by the password-reset screen.
///
/// We pass the OTP code from the OTP screen straight through to
/// `/new-password` instead of verifying it separately, because the backend's
/// reset-password handler re-validates the OTP itself and `verify` would
/// mark the code as used.
class NewPasswordArgs {
  final String email;
  final String otpCode;

  const NewPasswordArgs({required this.email, required this.otpCode});
}
