import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readx/features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/new_password_page.dart';
import '../../features/auth/presentation/pages/new_password_args.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/library_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/quotes/presentation/pages/quotes_page.dart';
import '../../features/quotes/presentation/pages/add_quote_page.dart';
import '../../features/quotes/presentation/bloc/quotes_bloc.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reader/presentation/pages/reading_page.dart';
import '../../features/reader/presentation/pages/epub_reader_page.dart';
import '../../features/home/presentation/pages/book_details_page.dart';
import '../widgets/main_shell.dart';
import '../../features/shop/presentation/pages/shop_reader_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/reports/presentation/pages/my_reports_page.dart';
import '../constants/app_theme.dart';
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/levels/presentation/pages/levels_roadmap_page.dart';
import '../../features/reader_profile/presentation/pages/reader_profile_page.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../di/injection_container.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/author_dashboard/presentation/pages/author_dashboard_page.dart';
import '../../features/author_dashboard/presentation/pages/author_books_page.dart';
import '../../features/author_dashboard/presentation/pages/author_main_shell.dart';

import '../../features/author_dashboard/presentation/pages/author_book_detail_page.dart';
import '../../features/author_dashboard/data/models/author_book_model.dart';
// Global key for navigator (needed for push from within shell)
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────
// Reusable transition builders
// ─────────────────────────────────────────────────────────

/// Slide from right + fade. Used for auth flow.
CustomTransitionPage<T> _slideFadePage<T>({
  required LocalKey? key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Smooth fade. Used for tabs and primary screens.
CustomTransitionPage<T> _fadePage<T>({
  required LocalKey? key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Scale + fade. Used for modal-like full-screen pushes (book details).
CustomTransitionPage<T> _scaleFadePage<T>({
  required LocalKey? key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    debugLogDiagnostics: true,
    routes: [
      // ── Onboarding ──────────────────────────────────
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const WelcomePage(),
        ),
      ),

      // ── Auth ────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _slideFadePage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _slideFadePage(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),

      // ── Email Verification ──────────────────────────
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final email = state.extra is String ? state.extra as String : '';
          return _slideFadePage(
            key: state.pageKey,
            child: OtpPage(email: email, isPasswordReset: false),
          );
        },
      ),

      // ── Forgot Password ─────────────────────────────
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _slideFadePage(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/reset-otp',
        pageBuilder: (context, state) {
          final email = state.extra is String ? state.extra as String : '';
          return _slideFadePage(
            key: state.pageKey,
            child: OtpPage(email: email, isPasswordReset: true),
          );
        },
      ),
      GoRoute(
        path: '/new-password',
        pageBuilder: (context, state) {
          final extra = state.extra;
          // Reset flow always pushes a `NewPasswordArgs` carrying the OTP code,
          // because `/api/users/reset-password` re-validates the code.
          // Allow a bare String fallback so a deep link without an OTP still
          // renders (the user will hit a backend validation error on submit).
          final args = extra is NewPasswordArgs
              ? extra
              : NewPasswordArgs(email: extra is String ? extra : '', otpCode: '');
          return _slideFadePage(
            key: state.pageKey,
            child: NewPasswordPage(args: args),
          );
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
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const HomePage()),
              ),
            ],
          ),
          // Tab 1: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const LibraryPage()),
              ),
            ],
          ),
          // Tab 2: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const SearchPage()),
              ),
            ],
          ),
          // Tab 3: Quotes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quotes',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const QuotesPage()),
              ),
            ],
          ),
          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const ProfilePage()),
              ),
            ],
          ),
        ],
      ),

      // ── Author Shell (Dashboard / Requests / Profile) ─
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthorMainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/author',
                pageBuilder: (context, state) => _fadePage(
                  key: state.pageKey,
                  child: const AuthorDashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/author/requests',
                pageBuilder: (context, state) => _fadePage(
                  key: state.pageKey,
                  child: const AuthorBooksPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/author/profile',
                pageBuilder: (context, state) =>
                    _fadePage(key: state.pageKey, child: const ProfilePage()),
              ),
            ],
          ),
        ],
      ),

      // ── Author Statistics / Book Detail (modals) ───────
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
        pageBuilder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '1';
          return _scaleFadePage(
            key: state.pageKey,
            child: BlocProvider<ProfileBloc>.value(
              value: sl<ProfileBloc>(),
              child: BookDetailsPage(bookId: bookId),
            ),
          );
        },
      ),

      // ── Add a Quote (manual or pre-filled from reader) ─────
      GoRoute(
        path: '/add-quote',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final args = state.extra is AddQuoteArgs
              ? state.extra as AddQuoteArgs
              : const AddQuoteArgs();
          return _slideFadePage(
            key: state.pageKey,
            child: BlocProvider<QuotesBloc>.value(
              value: sl<QuotesBloc>(),
              child: AddQuotePage(args: args),
            ),
          );
        },
      ),

      // ── Shop Book Reader (full-screen) ─────────────
      GoRoute(
        path: '/shop-reader/:bookId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? 'sb1';
          return _slideFadePage(
            key: state.pageKey,
            child: ShopReaderPage(bookId: bookId),
          );
        },
      ),

      // ── Reader (full-screen) ─────────
      GoRoute(
        path: '/reader/:bookId/:chapter',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final bookId = state.pathParameters['bookId'] ?? '1';
          final chapter =
              int.tryParse(state.pathParameters['chapter'] ?? '1') ?? 1;
          return _slideFadePage(
            key: state.pageKey,
            child: ReadingPage(bookId: bookId, chapterNumber: chapter),
          );
        },
      ),

      // ── EPUB Reader (full-screen) ─────
      GoRoute(
        path: '/epub-reader',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final epubUrl = state.uri.queryParameters['url'] ?? '';
          final bookTitle =
              state.uri.queryParameters['title'] ?? 'Epub Reader';
          final bookIdStr = state.uri.queryParameters['id'] ?? '1';
          final cleanedId = bookIdStr.replaceAll('api_', '');
          final bookId = int.tryParse(cleanedId) ?? 1;
          return _slideFadePage(
            key: state.pageKey,
            child: EpubReaderPage(
              bookId: bookId,
              epubUrl: epubUrl,
              bookTitle: bookTitle,
            ),
          );
        },
      ),

      // ── Notifications (full-screen) ────
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFadePage(
          key: state.pageKey,
          child: Scaffold(
      
            body: const SafeArea(child: NotificationsPage()),
          ),
        ),
      ),

      // ── Reports (full-screen, no bottom nav) ──────────
      GoRoute(
        path: '/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyReportsPage(),
      ),

      // ── AI Chat (full-screen) ─────────────────────────
      GoRoute(
        path: '/ai-chat',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideFadePage(
          key: state.pageKey,
          child: const AiChatPage(),
        ),
      ),

      // ── Reader Levels Roadmap ─────────────────────────
      GoRoute(
        path: '/levels',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _slideFadePage(
            key: state.pageKey,
            child: LevelsRoadmapPage(
              currentLevelId: extra['levelId'] as int?,
              totalTokens: extra['tokens'] as int? ?? 0,
            ),
          );
        },
      ),

      // ── Reader Profile (public view) ──────────────────
      GoRoute(
        path: '/reader-profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '') ?? 0;
          return _slideFadePage(key: state.pageKey, child: ReaderProfilePage(userId: userId));
        },
      ),
    ],
  );
}
