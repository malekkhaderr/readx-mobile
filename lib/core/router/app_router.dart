import 'package:go_router/go_router.dart';
import 'package:readx/features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: true,
    routes: [
      // ── Onboarding ──────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),

      // ── Auth ────────────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // ── Email Verification ──────────────────────────
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final email = state.extra as String? ?? 'test@example.com';
          return OtpPage(email: email, isPasswordReset: false);
        },
      ),

      // ── Forgot Password ─────────────────────────────
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-otp',
        builder: (context, state) {
          final email = state.extra as String? ?? 'test@example.com';
          return OtpPage(email: email, isPasswordReset: true);
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (context, state) {
          final email = state.extra as String? ?? 'test@example.com';
          return NewPasswordPage(email: email);
        },
      ),
    ],
  );
}
