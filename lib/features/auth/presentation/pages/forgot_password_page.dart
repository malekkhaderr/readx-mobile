import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/animated_owl.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (!_submitted) return null;
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    return null;
  }

  void _onSubmit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      ForgotPasswordEvent(email: _emailController.text.trim()),
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
        }
        if (state is ForgotPasswordSent) {
          context.go('/reset-otp', extra: state.email);
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
                              onPressed: () => context.go('/login'),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Title ────────────────────────
                          const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No worries! Enter your email and we\'ll send you a reset code.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Email ────────────────────────
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (_) {
                              if (_submitted) {
                                _formKey.currentState!.validate();
                              }
                            },
                            validator: _validateEmail,
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Submit Button ────────────────
                          ElevatedButton(
                            onPressed: isLoading ? null : _onSubmit,
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send Reset Code'),
                          ),
                          const SizedBox(height: 24),

                          // ── Back to login ────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Remember your password? ',
                                style: TextStyle(color: AppColors.textGrey),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text(
                                  'Log in',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
