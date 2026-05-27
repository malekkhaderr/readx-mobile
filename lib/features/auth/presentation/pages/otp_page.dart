import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/animated_owl.dart';
import '../../data/datasources/auth_remote_datasource.dart' show OtpPurpose;
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'new_password_args.dart';

class OtpPage extends StatelessWidget {
  final String email;
  final bool isPasswordReset;

  const OtpPage({super.key, required this.email, this.isPasswordReset = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: _OtpView(email: email, isPasswordReset: isPasswordReset),
    );
  }
}

class _OtpView extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const _OtpView({required this.email, required this.isPasswordReset});

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _resendSeconds = 60;
  bool _canResend = false;
  Timer? _resendTimer;

  /// `_lastAction` lets the BlocListener know how to react when an `AuthLoading`
  /// transitions to `OtpVerified` / `OtpSent` — both states are emitted by the
  /// bloc but the UI behaviour depends on which button the user just pressed.
  _OtpAction _lastAction = _OtpAction.none;

  int get _purpose => widget.isPasswordReset
      ? OtpPurpose.forgotPassword
      : OtpPurpose.emailVerification;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 4;

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onVerify() {
    if (!_isComplete) return;
    if (widget.isPasswordReset) {
      // For the forgot-password flow we skip an explicit verify call. The
      // backend's `/api/users/reset-password` re-validates the OTP atomically
      // when the user submits their new password, so verifying separately
      // would `MarkAsUsed` and break the subsequent reset call.
      context.go(
        '/new-password',
        extra: NewPasswordArgs(email: widget.email, otpCode: _otp),
      );
      return;
    }
    _lastAction = _OtpAction.verify;
    context.read<AuthBloc>().add(
      VerifyOtpEvent(email: widget.email, code: _otp, purpose: _purpose),
    );
  }

  void _onResend() {
    if (!_canResend) return;
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    _lastAction = _OtpAction.resend;
    context.read<AuthBloc>().add(
      SendOtpEvent(email: widget.email, purpose: _purpose),
    );
  }

  void _handleVerifySuccess() {
    if (widget.isPasswordReset) {
      context.go('/new-password', extra: widget.email);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified! Please log in.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go('/login');
  }

  void _handleResendSuccess() {
    _startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new code has been sent to your email.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        if (state is OtpVerified && _lastAction == _OtpAction.verify) {
          _handleVerifySuccess();
        }
        if (state is OtpSent && _lastAction == _OtpAction.resend) {
          _handleResendSuccess();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ───────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: AppColors.primary,
                              ),
                              onPressed: () => widget.isPasswordReset
                                  ? context.go('/forgot-password')
                                  : context.go('/register'),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const AnimatedOwl(size: 120),
                      ],
                    ),
                  ),

                  // ── Form Card ────────────────────────────
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.60,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ────────────────────────────
                        Text(
                          widget.isPasswordReset
                              ? 'Enter Reset Code'
                              : 'Verify Your Email',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                            children: [
                              TextSpan(
                                text: widget.isPasswordReset
                                    ? 'We sent a reset code to\n'
                                    : 'We sent a 4-digit code to\n',
                              ),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── OTP Fields ────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return SizedBox(
                              width: 68,
                              height: 68,
                              child: TextFormField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) =>
                                    _onChanged(value, index),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor:
                                      _controllers[index].text.isNotEmpty
                                      ? AppColors.primaryLight
                                      : AppColors.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          _controllers[index].text.isNotEmpty
                                          ? AppColors.primary
                                          : AppColors.divider,
                                      width:
                                          _controllers[index].text.isNotEmpty
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),

                        // ── Verify Button ──────────────────────
                        ElevatedButton(
                          onPressed:
                              _isComplete && !isLoading ? _onVerify : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isComplete
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                          child: isLoading && _lastAction == _OtpAction.verify
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isPasswordReset
                                      ? 'Verify Code'
                                      : 'Verify Email',
                                ),
                        ),
                        const SizedBox(height: 24),

                        // ── Resend ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive the code? ",
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                            if (_canResend)
                              TextButton(
                                onPressed:
                                    isLoading ? null : _onResend,
                                child: const Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'Resend in ${_resendSeconds}s',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _OtpAction { none, verify, resend }
