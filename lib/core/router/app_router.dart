import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readx/features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/library_page.dart';
import '../../features/shop/presentation/pages/book_shop_page.dart';
import '../../features/quotes/presentation/pages/quotes_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reader/presentation/pages/reading_page.dart';
import '../../features/home/presentation/pages/book_details_page.dart';
import '../widgets/main_shell.dart';
import '../../features/shop/presentation/pages/shop_reader_page.dart';

// Global key for navigator (needed for push from within shell)
final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
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
          final email = state.extra is String ? state.extra as String : '';
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
          final email = state.extra is String ? state.extra as String : '';
          return OtpPage(email: email, isPasswordReset: true);
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (context, state) {
          final email = state.extra is String ? state.extra as String : '';
          return NewPasswordPage(email: email);
        },
      ),
      // ── Main App Shell (Bottom Navigation) ──────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // Tab 1: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
          // Tab 2: Shop
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => const BookShopPage(),
              ),
            ],
          ),
          // Tab 3: Quotes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quotes',
                builder: (context, state) => const QuotesPage(),
              ),
            ],
          ),
          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ── Book Details (full-screen, no bottom nav) ──────
      GoRoute(
        path: '/book/:bookId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '1';
          return BookDetailsPage(bookId: bookId);
        },
      ),

      // ── Shop Book Reader (full-screen, no bottom nav) ────
      GoRoute(
        path: '/shop-reader/:bookId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? 'sb1';
          return ShopReaderPage(bookId: bookId);
        },
      ),

      // ── Reader (full-screen, no bottom nav) ─────────
      GoRoute(
        path: '/reader/:bookId/:chapter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '1';
          final chapter = int.tryParse(state.pathParameters['chapter'] ?? '1') ?? 1;
          return ReadingPage(bookId: bookId, chapterNumber: chapter);
        },
      ),
    ],
  );
}
