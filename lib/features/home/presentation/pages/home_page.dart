import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/feather_widgets.dart';
import '../../../../core/widgets/expressive_owl.dart';
import '../../../../core/widgets/streak_fire.dart';
import '../../../focus_timer/data/focus_timer_service.dart';
import '../../../../core/widgets/daily_quote_splash.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../../data/models/home_response_model.dart';
import 'package:flutter/foundation.dart';
import '../../../notifications/data/datasources/notifications_remote_datasource.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    sl<LibraryBloc>().add(const LoadLibraryEvent());
    // Wait for profile to be ready, then load unread count
    _waitForProfileAndLoadCount();
    // Show daily quote splash on every app open
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) DailyQuoteSplash.show(context);
    });
  }

  void _waitForProfileAndLoadCount() async {
    // If profile is already loaded, fetch immediately
    if (sl<ProfileBloc>().state is ProfileLoaded) {
      _loadUnreadCount();
      return;
    }
    // Otherwise listen for it to load
    await for (final state in sl<ProfileBloc>().stream) {
      if (state is ProfileLoaded) {
        _loadUnreadCount();
        break;
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    final profileState = sl<ProfileBloc>().state;
    if (profileState is! ProfileLoaded) return;
    try {
      final ds = sl<NotificationsRemoteDataSource>();
      final notifications = await ds.getNotifications(profileState.profile.id);
      final unread = notifications.where((n) => !n.isRead).length;
      if (mounted) setState(() => _unreadNotificationCount = unread);
    } catch (e) {
      debugPrint('Failed to load unread count: $e');
    }
  }

  Future<void> _onRefresh() async {
    context.read<HomeBloc>().add(const RefreshHomeEvent());
    sl<LibraryBloc>().add(const RefreshLibraryEvent());
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    final UserProfileEntity? profile =
        profileState is ProfileLoaded ? profileState.profile : null;

    return BlocProvider.value(
      value: sl<LibraryBloc>(),
      child: Scaffold(
  
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Gradient Header ─────────────────
            SliverToBoxAdapter(
              child: _GradientHeader(
                profile: profile,
                unreadCount: _unreadNotificationCount,
                onNotificationsClosed: _loadUnreadCount,
              ),
            ),

            // ── Expressive Owl ────────────────────
            SliverToBoxAdapter(
              child: _OwlMoodWidget(),
            ),

            // ── Search Bar ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _SearchBar(),
              ),
            ),

            // ── Stats Row ──────────────────────
            if (profile?.readerDashboard != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _StatsStrip(profile: profile!),
                ),
              ),

            // Focus Timer — live card
            SliverToBoxAdapter(
              child: _FocusTimerCard(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Main Content ─────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading && state.isFirstFetch) {
                    return const _HomeSkeleton();
                  } else if (state is HomeError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: _onRefresh,
                    );
                  } else if (state is HomeLoaded) {
                    final data = state.data;
                    final featured = _pickFeaturedBook(data);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured Hero Card with pulse
                        if (featured != null)
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 100),
                            duration: const Duration(milliseconds: 600),
                            child: PulseGlow(
                              maxScale: 1.015,
                              duration: const Duration(milliseconds: 2400),
                              child: _FeaturedHeroCard(
                                book: featured,
                                onTap: () =>
                                    context.push('/book/${featured.id}'),
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),

                        if (data.trendingBooks.isNotEmpty) ...[
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: _SectionHeader(
                              title: 'Trending Now',
                              icon: Icons.local_fire_department_rounded,
                              iconColor: const Color(0xFFFF6B35),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 250),
                            child: _BookHorizontalList(
                              books: data.trendingBooks,
                              onBookTap: (id) => context.push('/book/$id'),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        if (data.recommendedBooks.isNotEmpty) ...[
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 350),
                            child: _SectionHeader(
                              title: 'Recommended for You',
                              icon: Icons.auto_awesome_rounded,
                              iconColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 400),
                            child: _BookHorizontalList(
                              books: data.recommendedBooks,
                              onBookTap: (id) => context.push('/book/$id'),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Daily Tip Banner
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 500),
                          child: _DailyTipBanner(),
                        ),
                        const SizedBox(height: 28),

                        if (data.newlyAddedBooks.isNotEmpty) ...[
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 600),
                            child: _SectionHeader(
                              title: 'Newly Added',
                              icon: Icons.new_releases_rounded,
                              iconColor: AppColors.successGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 650),
                            child: _BookHorizontalList(
                              books: data.newlyAddedBooks,
                              onBookTap: (id) => context.push('/book/$id'),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Categories
                        if (data.categories.isNotEmpty)
                          ...data.categories
                              .where((c) => c.books.isNotEmpty)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => FadeSlideIn(
                                  delay: Duration(
                                      milliseconds: 750 + entry.key * 100),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 28),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SectionHeader(
                                          title: entry.value.categoryName,
                                          icon: Icons.bookmark_rounded,
                                          iconColor: AppColors.gold,
                                        ),
                                        const SizedBox(height: 12),
                                        _BookHorizontalList(
                                          books: entry.value.books,
                                          onBookTap: (id) =>
                                              context.push('/book/$id'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      ),
    );
  }

  BookCard? _pickFeaturedBook(dynamic data) {
    final candidates = <BookCard>[];
    if (data.trendingBooks != null && data.trendingBooks.isNotEmpty) {
      candidates.addAll(
          (data.trendingBooks as List<BookCard>).where((b) => b.isPublished));
    }
    if (candidates.isEmpty &&
        data.recommendedBooks != null &&
        data.recommendedBooks.isNotEmpty) {
      candidates.addAll((data.recommendedBooks as List<BookCard>)
          .where((b) => b.isPublished));
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return candidates.first;
  }
}

// ─────────────────────────────────────────────────────────
// GRADIENT HEADER
// ─────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final UserProfileEntity? profile;
  final int unreadCount;
  final VoidCallback? onNotificationsClosed;
  const _GradientHeader({this.profile, this.unreadCount = 0, this.onNotificationsClosed});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = profile?.firstName ?? '';
    final levelLabel = profile?.readerDashboard?.levelLabel ?? '';
    final hasAvatar = profile?.hasAvatar ?? false;
    final avatarUrl = profile?.avatarImageUrl;
    final avatarInitial = profile?.avatarInitial ?? '?';
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 16, 22),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _avatarFallback(avatarInitial),
                    )
                  : Image.asset('assets/images/owl.png',
                      width: 50, height: 50, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(_getGreetingEmoji(),
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  firstName.isNotEmpty ? firstName : 'Welcome back',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                if (levelLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 11, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          levelLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Notification button
          GestureDetector(
            onTap: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const NotificationsPage(),
              );
              onNotificationsClosed?.call();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 20),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
              color: AppColors.surface, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SEARCH BAR (visual only — taps go to search tab)
// ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/search'),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: AppColors.textGrey, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search books, authors, genres...',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded,
                  color: AppColors.primary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// STATS STRIP
// ─────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final UserProfileEntity profile;
  const _StatsStrip({required this.profile});

  @override
  Widget build(BuildContext context) {
    final dash = profile.readerDashboard!;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            value: '${dash.booksRead}',
            label: 'Books',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${dash.streakDays}',
            label: 'Day Streak',
            color: const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_florist_rounded, // fallback (won't render)
            iconAsset: 'assets/images/purple_feather.png',
            value: dash.formattedCubes,
            label: 'Feathers',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String? iconAsset;
  final String value;
  final String label;
  final Color color;
  const _StatCard({
    required this.icon,
    this.iconAsset,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(iconAsset!, fit: BoxFit.contain),
                  )
                : Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FEATURED HERO CARD
// ─────────────────────────────────────────────────────────

class _FeaturedHeroCard extends StatelessWidget {
  final BookCard book;
  final VoidCallback onTap;
  const _FeaturedHeroCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, libState) {
        final isOwned = libState is LibraryLoaded &&
            libState.books.any((b) => b.bookId == book.id);
        return _buildCard(context, isOwned);
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isOwned) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF2D1B4E), AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Decorative circles
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 60,
                  bottom: -40,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                // Content row
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Cover
                      Container(
                        width: 100,
                        height: 144,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: book.coverImageUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: book.coverImageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _heroCoverFallback(),
                                )
                              : _heroCoverFallback(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOwned
                                    ? AppColors.successGreen.withOpacity(0.85)
                                    : AppColors.gold.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOwned
                                        ? Icons.check_circle_rounded
                                        : Icons.local_fire_department_rounded,
                                    size: 10,
                                    color: isOwned
                                        ? Colors.white
                                        : AppColors.gold,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isOwned ? 'OWNED' : 'FEATURED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isOwned
                                          ? Colors.white
                                          : AppColors.gold,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${book.authorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // CTA — label depends on ownership
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOwned
                                        ? Icons.menu_book_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOwned ? 'Read Now' : 'View Details',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCoverFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/search'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.primary.withOpacity(0.85)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HORIZONTAL BOOK LIST
// ─────────────────────────────────────────────────────────

class _BookHorizontalList extends StatelessWidget {
  final List<BookCard> books;
  final void Function(int bookId) onBookTap;
  const _BookHorizontalList({
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final publishedBooks = books.where((b) => b.isPublished).toList();
    if (publishedBooks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 282,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: publishedBooks.length,
        itemBuilder: (context, index) {
          final book = publishedBooks[index];
          return ScaleOnTap(
            onTap: () => onBookTap(book.id),
            child: _BookListCard(book: book),
          );
        },
      ),
    );
  }
}

class _BookListCard extends StatelessWidget {
  final BookCard book;
  const _BookListCard({required this.book});

  // Always show real prices so users can recall what they paid,
  // even after they own the book. Ownership is shown as a corner badge.
  Widget _buildPriceWidget(BookCard book) {
    return PriceTag(
      priceUSD: book.priceUSD,
      priceFeathers: book.priceTokens,
      isFree: book.isFree,
      compact: true,
    );
  }

  bool _isOwnedFromState(LibraryState state) {
    if (state is LibraryLoaded) {
      return state.books.any((b) => b.bookId == book.id);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, libState) {
        final isOwned = _isOwnedFromState(libState);
        return _buildCard(context, isOwned);
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isOwned) {
    return Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover with overlays (Hero linked to BookDetailsPage)
          Hero(
            tag: 'book-cover-${book.id}',
            child: Container(
            height: 184,
            width: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  // Only call CachedNetworkImage when the URL is a real http(s)
                  // url; otherwise garbage like "test.com" or "1234" would
                  // trigger a slow doomed network call before falling back.
                  child: book.coverImageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: book.coverImageUrl,
                          width: 130,
                          height: 184,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.primaryLight,
                            highlightColor: AppColors.shimmer,
                            child: Container(
                              width: 130,
                              height: 184,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          errorWidget: (_, __, ___) => _coverFallback(),
                        )
                      : _coverFallback(),
                ),
                // Gradient overlay at bottom for legibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          book.averageRating > 0
                              ? book.averageRating.toStringAsFixed(1)
                              : '—',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Owned badge takes priority — otherwise show FREE if applicable
                if (isOwned)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successGreen.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 9, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'OWNED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (book.isFree)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Views at bottom
                if (book.viewCount > 0)
                  Positioned(
                    bottom: 7,
                    left: 8,
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(book.viewCount),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ), // close Hero
          const SizedBox(height: 10),
          // Title — reserves a fixed 2-line slot so every card stays the same
          // height regardless of whether the title is short or long. This
          // matches the search-page grid alignment.
          SizedBox(
            height: 34, // 2 lines × 12.5px × 1.3 line-height ≈ 32.5px
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14, // 1 line author
            child: Text(
              book.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildPriceWidget(book),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────
// DAILY TIP BANNER
// ─────────────────────────────────────────────────────────

class _DailyTipBanner extends StatelessWidget {
  static const List<String> _tips = [
    'Reading 15 minutes before bed can improve your sleep quality by 68%. Try a chapter tonight!',
    'Reading just 6 minutes a day can lower stress by up to 60%. Take a breath, take a book.',
    'Re-reading a favourite passage builds long-term memory faster than reading something new.',
    'Highlight a sentence that surprised you — quotes you collect become quotes you live by.',
    'A short paragraph at lunch beats a long chapter you never start. Small bites win.',
    'Books finished on weekends count double — your future self will remember the streak.',
    'Try a different genre this week. The brain learns most from the unfamiliar.',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().weekday % _tips.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/owl.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        "HOOTIE'S DAILY TIP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark.withOpacity(0.85),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SKELETON LOADER
// ─────────────────────────────────────────────────────────

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmer,
        highlightColor: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 28),
            // Section title placeholder
            Container(
              width: 160,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            // Book cards row
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 130,
                        height: 184,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 110,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 70,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => onRetry(),
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(180, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus Timer Card (shows on home page) ────────────────────
class _FocusTimerCard extends StatefulWidget {
  @override
  State<_FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends State<_FocusTimerCard> with SingleTickerProviderStateMixin {
  final _timer = FocusTimerService();
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _timer.addListener(_onTick);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.removeListener(_onTick);
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onTick() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final isRunning = _timer.isRunning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () => context.push('/focus-timer'),
        child: isRunning ? _buildRunningCard() : _buildIdleCard(),
      ),
    );
  }

  Widget _buildIdleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        // Owl reading icon
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.12), AppColors.primary.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/images/owl_reading.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Focus Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text('Start a session, read freely, earn feathers', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
        ])),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.primary),
        ),
      ]),
    );
  }

  Widget _buildRunningCard() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.2 + _glowCtrl.value * 0.1), blurRadius: 16 + _glowCtrl.value * 6, spreadRadius: _glowCtrl.value * 2, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
      child: Row(children: [
        // Live timer display
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Center(
            child: Text(_timer.formattedTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace')),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4)])),
            const SizedBox(width: 6),
            Text('Focus Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          const SizedBox(height: 4),
          Text('Reading session in progress • Tap to view', style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
        ])),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white.withOpacity(0.9)),
        ),
      ]),
    );
  }
}


// ── TEST — Owl mood cycle (remove after testing) ────────────
class _OwlMoodWidget extends StatefulWidget {
  @override
  State<_OwlMoodWidget> createState() => _OwlMoodWidgetState();
}

class _OwlMoodWidgetState extends State<_OwlMoodWidget> {
  int _i = 0;
  final _moods = OwlMood.values;
  final _labels = ['Wave', 'Happy', 'Sad', 'Celebrate', 'Read', 'Sleep'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(children: [
        ExpressiveOwl(mood: _moods[_i], size: 140),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _i = (_i + 1) % _moods.length),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
            child: Text('Owl: ${_labels[_i]}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
