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
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/quotes/presentation/pages/quotes_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reader/presentation/pages/reading_page.dart';
import '../../features/reader/presentation/pages/epub_reader_page.dart';
import '../../features/home/presentation/pages/book_details_page.dart';
import '../widgets/main_shell.dart';
import '../../features/shop/presentation/pages/shop_reader_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/reports/presentation/pages/my_reports_page.dart';
import '../constants/app_theme.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../di/injection_container.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/author_dashboard/presentation/pages/author_dashboard_page.dart';
import '../../features/author_dashboard/presentation/pages/author_books_page.dart';
import '../../features/author_dashboard/presentation/pages/author_main_shell.dart';
import '../../features/author_dashboard/presentation/pages/author_statistics_page.dart';
import '../../features/author_dashboard/presentation/pages/author_book_detail_page.dart';
import '../../features/author_dashboard/data/models/author_book_model.dart';
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
          // Tab 2: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchPage(),
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

      // ── Author App Shell (Bottom Navigation) ────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthorMainShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/author',
                builder: (context, state) => const AuthorDashboardPage(),
              ),
            ],
          ),
          // Tab 1: Requests
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/author/books',
                builder: (context, state) => const AuthorBooksPage(),
              ),
            ],
          ),
          // Tab 2: Profile (reuses reader profile page)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/author/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/author/statistics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthorStatisticsPage(),
      ),

      GoRoute(
        path: '/author/book_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null || extra['book'] == null) {
            // Fallback just in case, though it shouldn't happen.
            return const Scaffold(body: Center(child: Text('Error: Book not found')));
          }
          return AuthorBookDetailPage(
            book: extra['book'] as AuthorBook,
            quotesCount: extra['quotesCount'] as int?,
          );
        },
      ),

      GoRoute(
        path: '/book/:bookId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '1';
          return BlocProvider<ProfileBloc>.value(
            value: sl<ProfileBloc>(),
            child: BookDetailsPage(bookId: bookId),
          );
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

      // ── EPUB Reader (full-screen, no bottom nav) ─────
      GoRoute(
        path: '/epub-reader',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final epubUrl = state.uri.queryParameters['url'] ?? '';
          final bookTitle = state.uri.queryParameters['title'] ?? 'Epub Reader';
          final bookIdStr = state.uri.queryParameters['id'] ?? '1';
          final cleanedId = bookIdStr.replaceAll('api_', '');
          final bookId = int.tryParse(cleanedId) ?? 1;
          return EpubReaderPage(
            bookId: bookId,
            epubUrl: epubUrl,
            bookTitle: bookTitle,
          );
        },
      ),

      // ── Notifications (full-screen, no bottom nav) ────
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: const NotificationsPage()),
        ),
      ),

      // ── Reports (full-screen, no bottom nav) ──────────
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyReportsPage(),
      ),
    ],
  );
}
