import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/author_quotes_stats_model.dart';
import '../bloc/author_dashboard_bloc.dart';
import '../widgets/author_book_list_card.dart';
import '../pages/author_book_detail_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_event.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../../../core/di/injection_container.dart';

class AuthorDashboardPage extends StatelessWidget {
  const AuthorDashboardPage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    final UserProfileEntity? profile = profileState is ProfileLoaded
        ? profileState.profile
        : null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<AuthorDashboardBloc>().add(
              RefreshAuthorDashboardEvent(),
            );
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ── Header ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: profile != null && profile.hasAvatar
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profile.avatarImageUrl!,
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Center(
                                    child: Text(
                                      profile.avatarInitial,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ClipOval(
                                child: Image.asset(
                                  'assets/images/owl.png',
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile != null
                                        ? 'Good ${_getGreeting()}, ${profile.firstName} ✍️'
                                        : 'Good ${_getGreeting()}! ✍️',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Author Dashboard',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notifications Bell
                      BlocProvider<NotificationsBloc>(
                        create: (context) {
                          final bloc = sl<NotificationsBloc>();
                          final profileState = sl<ProfileBloc>().state;
                          if (profileState is ProfileLoaded) {
                            bloc.add(
                              FetchNotificationsEvent(profileState.profile.id),
                            );
                          }
                          return bloc;
                        },
                        child: BlocListener<ProfileBloc, ProfileState>(
                          bloc: sl<ProfileBloc>(),
                          listenWhen: (prev, curr) =>
                              curr is ProfileLoaded && prev is! ProfileLoaded,
                          listener: (context, profileState) {
                            if (profileState is ProfileLoaded) {
                              context.read<NotificationsBloc>().add(
                                FetchNotificationsEvent(
                                  profileState.profile.id,
                                ),
                              );
                            }
                          },
                          child: BlocBuilder<NotificationsBloc, NotificationsState>(
                            builder: (context, state) {
                              int unreadCount = 0;
                              if (state is NotificationsLoaded) {
                                unreadCount = state.notifications
                                    .where((n) => !n.isRead)
                                    .length;
                              }

                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => const NotificationsPage(),
                                  ).then((_) {
                                    // Refresh notifications when sheet closes to reflect any marked-as-read changes
                                    final profileState =
                                        sl<ProfileBloc>().state;
                                    if (profileState is ProfileLoaded) {
                                      context.read<NotificationsBloc>().add(
                                        FetchNotificationsEvent(
                                          profileState.profile.id,
                                        ),
                                      );
                                    }
                                  });
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        color: AppColors.textDark,
                                        size: 20,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$unreadCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── BlocBuilder: Dashboard data ──────────────────────
                BlocBuilder<AuthorDashboardBloc, AuthorDashboardState>(
                  builder: (context, state) {
                    final bloc = context.read<AuthorDashboardBloc>();
                    final dashboard = bloc.cachedDashboard;
                    final books = bloc.cachedBooks;
                    final quotesStats = bloc.cachedQuotesStats;

                    // Loading
                    if ((state is AuthorDashboardLoading ||
                            state is AuthorDashboardInitial) &&
                        dashboard == null) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    // Error
                    if (state is AuthorDashboardError && dashboard == null) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 52,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Couldn\'t load your dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<AuthorDashboardBloc>().add(
                                    RefreshAuthorDashboardEvent(),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(140, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (dashboard != null) {
                      final totalReads = dashboard.totalReadsAcrossAllBooks;
                      final nextMilestone =
                          ((totalReads / 100).floor() + 1) * 100;
                      final progressPercent = totalReads > 0
                          ? (totalReads % 100) / 100.0
                          : 0.05;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Impact Banner ─────────────────────────
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Reader Impact',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Goal: $nextMilestone reads',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$totalReads',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        bottom: 6,
                                      ),
                                      child: Text(
                                        'total reads',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    minHeight: 8,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.25,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orangeAccent,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '"Your words are making an impact. Keep writing!"',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Stats Grid (2×2) ─────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.menu_book_rounded,
                                        value: dashboard.totalPublishedBooks
                                            .toString(),
                                        label: 'Books Published',
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.visibility_rounded,
                                        value: _formatCount(
                                          dashboard.totalViewsAcrossAllBooks,
                                        ),
                                        label: 'Total Views',
                                        color: const Color(0xFF2196F3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.auto_stories_rounded,
                                        value: _formatCount(
                                          dashboard.totalReadsAcrossAllBooks,
                                        ),
                                        label: 'Total Reads',
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Avg rating from books performance
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.star_rounded,
                                        value: () {
                                          final ratedBooks = dashboard
                                              .booksPerformance
                                              .where((b) => b.averageRating > 0.0)
                                              .toList();
                                          return ratedBooks.isNotEmpty
                                              ? (ratedBooks
                                                          .map((b) => b.averageRating)
                                                          .reduce((a, b) => a + b) /
                                                      ratedBooks.length)
                                                  .toStringAsFixed(1)
                                              : '0.0';
                                        }(),
                                        label: 'Avg Rating',
                                        color: AppColors.warningOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        icon: Icons.format_quote_rounded,
                                        value: _formatCount(
                                          quotesStats?.totalQuotesCount ?? 0,
                                        ),
                                        label: 'Total Quotes',
                                        color: Colors.purpleAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child:
                                          const SizedBox(), // Empty for now, but balances the grid
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── My Books Section ────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'My Books',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${books?.length ?? 0} books',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Tap any book to view full details and reader comments',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Books List
                          if (books == null || books.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.library_books_rounded,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No books yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Your published books will appear here.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                final quoteCount =
                                    quotesStats?.bookQuoteCounts
                                        .firstWhere(
                                          (q) => q.bookId == book.id,
                                          orElse: () => BookQuoteCountModel(
                                            bookId: book.id,
                                            bookTitle: '',
                                            quotesCount: 0,
                                          ),
                                        )
                                        .quotesCount ??
                                    0;

                                return AuthorBookListCard(
                                  book: book,
                                  quotesCount: quoteCount,
                                  onTap: () {
                                    context.push(
                                      '/author/book_detail',
                                      extra: {
                                        'book': book,
                                        'quotesCount': quoteCount,
                                      },
                                    );
                                  },
                                );
                              },
                            ),

                          const SizedBox(height: 32),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

// ─────────────────────────────────────────────────
// Stat Card Widget
// ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
