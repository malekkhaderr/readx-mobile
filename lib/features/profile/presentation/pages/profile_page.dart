import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
// Reward store imports removed (the section was hidden — see below).
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../quotes/presentation/bloc/quotes_bloc.dart';
import '../../../quotes/presentation/bloc/quotes_event.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart' show OtpPurpose;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart';

import '../../../author_dashboard/presentation/bloc/author_dashboard_bloc.dart';
import '../../../author_dashboard/presentation/pages/author_book_detail_page.dart';
import '../../../author_dashboard/data/models/author_book_model.dart';
import '../../../levels/presentation/widgets/level_badge_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ProfileBloc is provided by MainShell.
    // We inject AuthBloc locally to handle logout actions.
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // Wipe per-user blocs so the next user starts clean and doesn't
            // briefly see the previous user's profile/library/quotes.
            sl<ProfileBloc>().add(const ResetProfileEvent());
            sl<LibraryBloc>().add(const ResetLibraryEvent());
            sl<QuotesBloc>().add(const ResetQuotesEvent());
            // Once successfully logged out locally, redirect to welcome
            context.go('/welcome');
          } else if (state is AuthError) {
            // Even on error, we log out locally now. But if we want to show a toast:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: const _ProfileView(),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is ProfileError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<ProfileBloc>().add(const RefreshProfileEvent()),
            );
          }
          if (state is ProfileLoaded) {
            return _ProfileBody(profile: state.profile);
          }
            return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ── Error View ───────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textGrey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

// ── Main Profile Body ────────────────────────────────────────
class _ProfileBody extends StatefulWidget {
  final UserProfileEntity profile;
  const _ProfileBody({required this.profile});

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {

  void _showEditProfile() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _EditProfilePage(profile: widget.profile)),
    );
    if (result == true) {
      sl<ProfileBloc>().add(const RefreshProfileEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    // ── Route to the appropriate profile view based on role ──
    if (profile.isAuthor) {
      return _AuthorProfileBody(profile: profile, onLogout: () {
        context.read<AuthBloc>().add(const LogoutEvent());
      });
    }

    // ── Reader profile — Dark Glass Dashboard ─────────────────
    final dashboard = profile.readerDashboard;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProfileBloc>().add(const RefreshProfileEvent());
        await context.read<ProfileBloc>().stream.firstWhere((s) => s is! ProfileLoading);
      },
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Email verification banner ──────────────────
              if (!profile.isEmailVerified)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warningOrange.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.mail_outline, size: 16, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Verify your email', style: TextStyle(fontSize: 12, color: AppColors.warningOrange, fontWeight: FontWeight.w600))),
                    GestureDetector(
                      onTap: () {
                        context.read<AuthBloc>().add(SendOtpEvent(email: profile.email, purpose: OtpPurpose.emailVerification));
                        context.go('/otp', extra: profile.email);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.warningOrange, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Verify', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),

              const SizedBox(height: 24),

              // ── Hero Card — Avatar + Name + Level + Stats ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with glow ring
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 3),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                        ),
                        child: profile.hasAvatar
                            ? ClipOval(child: CachedNetworkImage(imageUrl: profile.avatarImageUrl!, width: 80, height: 80, fit: BoxFit.cover, errorWidget: (_, __, ___) => Center(child: Text(profile.avatarInitial, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)))))
                            : Center(child: Text(profile.avatarInitial, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Name
                    Text(profile.fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: -0.3)),
                    const SizedBox(height: 6),
                    // Level badge card with icon + progress
                    if (dashboard != null) ...[
                      const SizedBox(height: 4),
                      LevelBadgeCard(
                        levelId: dashboard.levelId,
                        levelLabel: dashboard.levelLabel,
                        totalTokensEarned: dashboard.totalTokensEarned,
                        tokenBalance: dashboard.cubes,
                        onTap: () => context.push('/levels', extra: {'levelId': dashboard.levelId, 'tokens': dashboard.totalTokensEarned}),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Stats row — glass cards
                    if (dashboard != null)
                      Row(children: [
                        _GlassStat(value: '${dashboard.booksRead}', label: 'Books', icon: Icons.menu_book_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        _GlassStat(value: '${dashboard.streakDays}', label: 'Streak', icon: Icons.local_fire_department_rounded, color: AppColors.warningOrange),
                        const SizedBox(width: 10),
                        _GlassStat(value: dashboard.totalReadingTime, label: 'Read', icon: Icons.schedule_rounded, color: AppColors.successGreen),
                      ]),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Action Button ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GlassActionButton(label: 'Edit Profile', icon: Icons.edit_outlined, onTap: _showEditProfile),
              ),

              const SizedBox(height: 16),

              // ── Reading Progress (daily goal) ──────────────
              if (dashboard != null && dashboard.dailyGoal > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.track_changes_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Daily Goal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const Spacer(),
                      Text('${dashboard.dailyGoal}m target', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (dashboard.weeklyRituals.isNotEmpty ? (dashboard.weeklyRituals.last.minutesRead / dashboard.dailyGoal).toDouble() : 0.0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ]),
                ),

              const SizedBox(height: 8),

              // ── Sections ───────────────────────────────────
              if (dashboard != null) ...[
                _ReadingRitualsSection(dashboard: dashboard),
                if (dashboard.completedBooks.isNotEmpty) _CompletedBooksSection(books: dashboard.completedBooks),
                _TrophyGridSection(trophies: dashboard.trophies),
              ] else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider, width: 0.8)),
                  child: Column(children: [
                    Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primary.withOpacity(0.4)),
                    const SizedBox(height: 14),
                    Text('Start Your Reading Journey', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text('Stats will appear as you read', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  ]),
                ),

              const SizedBox(height: 16),

              // ── Settings ───────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                ),
                child: Column(children: [
                  _SettingsTile(
                    icon: sl<ThemeProvider>().isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    label: 'Dark Mode',
                    trailing: Switch.adaptive(
                      value: sl<ThemeProvider>().isDark,
                      activeColor: AppColors.primary,
                      onChanged: (_) => sl<ThemeProvider>().toggle(),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.divider, indent: 52),
                  _SettingsTile(
                    icon: Icons.headset_mic_outlined,
                    label: 'Support Tickets',
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 20),
                    onTap: () => context.push('/reports'),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Logout ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.read<AuthBloc>().add(const LogoutEvent()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Author Profile Body ──────────────────────────────────────
// Clean, dedicated author profile — shows only author-relevant
// information. Reader sections (streaks, rituals, feathers,
// trophies) are never rendered here.
class _AuthorProfileBody extends StatelessWidget {
  final UserProfileEntity profile;
  final VoidCallback onLogout;
  const _AuthorProfileBody({required this.profile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    AuthorDashboardBloc? authorBloc;
    try {
      authorBloc = context.read<AuthorDashboardBloc>();
    } catch (_) {}

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProfileBloc>().add(const RefreshProfileEvent());
        await context.read<ProfileBloc>().stream.firstWhere((s) => s is! ProfileLoading);
      },
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Email verification banner ──────────────────
              if (!profile.isEmailVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.warningOrange.withOpacity(0.15),
                  child: Row(children: [
                    Icon(Icons.mail_outline, size: 18, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Please verify your email address.', style: TextStyle(fontSize: 13, color: AppColors.warningOrange, fontWeight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () {
                        context.read<AuthBloc>().add(SendOtpEvent(
                              email: profile.email,
                              purpose: OtpPurpose.emailVerification,
                            ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sending verification code…'),
                          ),
                        );
                        context.go('/otp', extra: profile.email);
                      },
                      child: Text('Verify', style: TextStyle(fontSize: 13, color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),

              // ── Author Info Header Card ────────────────────
              Container(
                margin: EdgeInsets.fromLTRB(20, 24, 20, 0),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: profile.hasAvatar
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile.avatarImageUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(profile.avatarInitial,
                                      style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(profile.avatarInitial,
                                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 16),
                    // Name + role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '✍️  Author',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      profile.isEmailVerified ? Icons.verified_rounded : Icons.cancel_outlined,
                                      size: 14,
                                      color: profile.isEmailVerified ? AppColors.successGreen : AppColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      profile.isEmailVerified ? 'Verified' : 'Not Verified',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: profile.isEmailVerified ? AppColors.successGreen : AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.email,
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Profile Info Fields ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  children: [
                    _InfoTile(icon: Icons.badge_outlined, label: 'Author ID', value: '#${profile.id}'),
                    _divider(),
                    _InfoTile(icon: Icons.email_outlined, label: 'Email', value: profile.email),
                    _divider(),
                    _InfoTile(
                      icon: profile.isEmailVerified ? Icons.verified_rounded : Icons.cancel_outlined,
                      label: 'Email Status',
                      value: profile.isEmailVerified ? 'Verified' : 'Not Verified',
                      valueColor: profile.isEmailVerified ? AppColors.successGreen : AppColors.error,
                    ),
                    _divider(),
                    InkWell(
                      onTap: () => context.push('/author/statistics'),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Detailed Statistics', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 2),
                                  Text('View Quotes & Book Stats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    _ModernGridTile(
                      icon: Icons.report_gmailerrorred_rounded,
                      label: 'My Reports',
                      value: 'View & Submit',
                      iconColor: AppColors.error,
                      iconBgColor: AppColors.error.withOpacity(0.1),
                      onTap: () => context.push('/reports'),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.report_gmailerrorred_rounded, size: 18, color: AppColors.error),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('My Reports', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 2),
                                  Text('View & Submit Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.error),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Published Books ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(children: [
                  Text('Published Books', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const Spacer(),
                  if (authorBloc != null)
                    BlocBuilder<AuthorDashboardBloc, AuthorDashboardState>(
                      builder: (ctx, s) {
                        final count = authorBloc!.cachedBooks?.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$count books', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        );
                      },
                    ),
                ]),
              ),

              if (authorBloc != null)
                BlocBuilder<AuthorDashboardBloc, AuthorDashboardState>(
                  builder: (context, state) {
                    final books = authorBloc!.cachedBooks;
                    if (state is AuthorDashboardLoading && (books == null || books.isEmpty)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (books == null || books.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Column(children: [
                          Text('📚', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No Books Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          SizedBox(height: 6),
                          Text('Your published books will appear here.', style: TextStyle(fontSize: 13, color: AppColors.textGrey), textAlign: TextAlign.center),
                        ]),
                      );
                    }
                    // 2-column grid of compact book cover cards
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return _AuthorBookGridCard(
                            book: book,
                            onTap: () => context.push('/author/book_detail', extra: {'book': book}),
                          );
                        },
                      ),
                    );
                  },
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Books unavailable', style: TextStyle(color: AppColors.textGrey))),
                ),


              const SizedBox(height: 28),

              // ── Dark Mode Toggle ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(sl<ThemeProvider>().isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text('Switch appearance', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ])),
                    Switch.adaptive(value: sl<ThemeProvider>().isDark, activeColor: AppColors.primary, onChanged: (_) => sl<ThemeProvider>().toggle()),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // ── Logout Button ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

}

class _ModernGridTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBgColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _ModernGridTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBgColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textDark)),
              ],
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


// ── Author Book Grid Card ─────────────────────────────────────
// Compact 2-per-row card: cover image + title + status + rating.
// Tapping navigates to the full AuthorBookDetailPage.
class _AuthorBookGridCard extends StatelessWidget {
  final AuthorBook book;
  final VoidCallback onTap;
  const _AuthorBookGridCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image ──────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or placeholder
                    book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _placeholder(),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    // Status pill overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: book.isPublished
                              ? AppColors.successGreen
                              : AppColors.warningOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.isPublished ? 'Live' : 'Draft',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: AppColors.warningOrange),
                      const SizedBox(width: 3),
                      Text(
                        book.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textGrey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 36),
      ),
    );
  }
}


// ── Action Button ────────────────────────────────────────────
// ── Glass Stat Card ──────────────────────────────────────────
class _GlassStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _GlassStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 0.8),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, spreadRadius: 0, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Glass Action Button ─────────────────────────────────────
class _GlassActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 0.8),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ]),
      ),
    );
  }
}

// ── Settings Tile ───────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark))),
          trailing,
        ]),
      ),
    );
  }
}

// ── Completed Books ──────────────────────────────────────────
class _CompletedBooksSection extends StatelessWidget {
  final List<CompletedBookEntity> books;
  const _CompletedBooksSection({required this.books});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Completed Books', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${books.length} books', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successGreen)),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                width: 80,
                margin: EdgeInsets.only(right: index < books.length - 1 ? 12 : 0),
                child: Column(children: [
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: book.coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: book.coverImageUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: AppColors.primaryLight,
                                highlightColor: AppColors.shimmer,
                                child: Container(width: 72, height: 72, color: AppColors.primaryLight),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.primaryLight,
                                  child: Icon(Icons.book, color: AppColors.primary)),
                            )
                          : Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.book, color: AppColors.primary)),
                    ),
                    Positioned(bottom: 4, right: 4, child: Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle), child: Icon(Icons.check, color: AppColors.surface, size: 10))),
                  ]),
                  const SizedBox(height: 6),
                  Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Reading Rituals — Modern Weekly View ─────────────────────
class _ReadingRitualsSection extends StatelessWidget {
  final ReaderDashboardEntity dashboard;
  const _ReadingRitualsSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final rituals = dashboard.weeklyRituals;
    final totalMinutes = rituals.fold(0, (sum, r) => sum + r.minutesRead);
    final activeDays = rituals.where((r) => r.minutesRead > 0).length;
    final maxMinutes = rituals.isEmpty ? 1 : rituals.map((r) => r.minutesRead).reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Text('Weekly Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.successGreen),
              const SizedBox(width: 3),
              Text('$activeDays/7', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.successGreen)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        // Bar chart
        if (rituals.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No activity this week', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ))
        else
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: rituals.map((r) {
                final hasActivity = r.minutesRead > 0;
                final reachedGoal = r.minutesRead >= dashboard.dailyGoal && dashboard.dailyGoal > 0;
                final barHeight = (r.minutesRead / maxMinutes * 70).clamp(4.0, 70.0);

                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    // Minutes label
                    if (hasActivity)
                      Text('${r.minutesRead}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: reachedGoal ? AppColors.successGreen : AppColors.primary)),
                    const SizedBox(height: 4),
                    // Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: hasActivity ? barHeight : 4,
                      decoration: BoxDecoration(
                        color: reachedGoal
                            ? AppColors.successGreen
                            : hasActivity
                                ? AppColors.primary
                                : AppColors.divider,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: reachedGoal ? [BoxShadow(color: AppColors.successGreen.withOpacity(0.3), blurRadius: 6)] : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Day label
                    Text(
                      r.day.length >= 3 ? r.day.substring(0, 3) : r.day,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hasActivity ? AppColors.textDark : AppColors.textGrey),
                    ),
                  ]),
                ));
              }).toList(),
            ),
          ),
        // Goal line label
        if (rituals.isNotEmpty && dashboard.dailyGoal > 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            Container(width: 12, height: 3, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text('${dashboard.dailyGoal}m daily goal', style: TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('${totalMinutes}m total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
        ],
      ]),
    );
  }
}

// ── Reward Store ─────────────────────────────────────────────
// _RewardStoreSection removed — backend rewards system isn't implemented
// yet and the section was driven entirely by MockShopData. The Reward Store
// will return when there's a real /api/rewards endpoint.

// ── Trophy Grid ──────────────────────────────────────────────
class _TrophyGridSection extends StatelessWidget {
  final List<TrophyEntity> trophies;
  const _TrophyGridSection({required this.trophies});

  @override
  Widget build(BuildContext context) {
    if (trophies.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Trophies & Runes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: trophies.take(6).map((t) => _TrophyItem(trophy: t)).toList()),
      ]),
    );
  }
}

class _TrophyItem extends StatelessWidget {
  final TrophyEntity trophy;
  const _TrophyItem({required this.trophy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            trophy.iconUrl != null
                ? CachedNetworkImage(
                    imageUrl: trophy.iconUrl!,
                    width: 64,
                    height: 64,
                    errorWidget: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 48)),
                  )
                : const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(trophy.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(trophy.earned ? 'Achievement unlocked! 🎉' : 'Keep reading to unlock this trophy!', style: TextStyle(color: AppColors.textGrey, fontSize: 13), textAlign: TextAlign.center),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        ),
      ),
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: trophy.earned ? AppColors.primaryLight : AppColors.divider.withOpacity(0.5), border: Border.all(color: trophy.earned ? AppColors.primary.withOpacity(0.3) : AppColors.divider, width: 2)),
          child: Center(
            child: trophy.iconUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: trophy.iconUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Text('🏆',
                          style: TextStyle(
                              fontSize: 22,
                              color: trophy.earned ? null : Colors.grey)),
                    ),
                  )
                : Text('🏆',
                    style: TextStyle(
                        fontSize: 22,
                        color: trophy.earned ? null : Colors.grey)),
          ),
        ),
        const SizedBox(height: 4),
        Text(trophy.name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: trophy.earned ? AppColors.textDark : AppColors.textGrey)),
      ]),
    );
  }
}



// ── Edit Profile Page (full-screen, avoids InheritedWidget conflicts) ──
class _EditProfilePage extends StatefulWidget {
  final UserProfileEntity profile;
  const _EditProfilePage({required this.profile});
  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  int _gender = 0;
  late bool _isPrivate;
  late int _dailyGoal;
  bool _saving = false;
  int? _selectedAvatarId;
  List<Map<String, dynamic>> _avatars = [];
  bool _loadingAvatars = true;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.profile.firstName);
    _lastNameCtrl = TextEditingController(text: widget.profile.lastName);
    _isPrivate = widget.profile.isPrivateProfile;
    _dailyGoal = widget.profile.readerDashboard?.dailyGoal ?? 30;
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    try {
      final response = await sl<DioClient>().dio.get('/avatars');
      if (response.statusCode == 200 && response.data is List) {
        _avatars = (response.data as List).map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAvatars = false);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await sl<DioClient>().dio.put('/users/profile/edit', data: {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _gender,
        'birthDate': '2000-01-01T00:00:00Z',
        'isPrivateProfile': _isPrivate,
        'avatarId': _selectedAvatarId,
        'dailyGoal': _dailyGoal,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to save'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Edit Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar Picker
          Text('Choose Avatar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          if (_loadingAvatars)
            SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
          else if (_avatars.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.face_rounded, color: AppColors.textGrey, size: 20),
                const SizedBox(width: 10),
                Text('No avatars available', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ]),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (context, i) {
                  final avatar = _avatars[i];
                  final id = avatar['id'] as int;
                  final imageUrl = avatar['imageUrl'] as String? ?? '';
                  final name = avatar['name'] as String? ?? '';
                  final isSelected = _selectedAvatarId == id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatarId = isSelected ? null : id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2.5 : 1),
                        boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10)] : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.startsWith('http')
                              ? Image.network(imageUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.face_rounded, size: 36, color: AppColors.primary))
                              : Icon(Icons.face_rounded, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: isSelected ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Text('First Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          TextFormField(controller: _firstNameCtrl, style: TextStyle(color: AppColors.textDark), decoration: InputDecoration(prefixIcon: Icon(Icons.person_outline, color: AppColors.textGrey))),
          const SizedBox(height: 16),
          Text('Last Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          TextFormField(controller: _lastNameCtrl, style: TextStyle(color: AppColors.textDark), decoration: InputDecoration(prefixIcon: Icon(Icons.person_outline, color: AppColors.textGrey))),
          const SizedBox(height: 20),
          Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setState(() => _gender = 0), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _gender == 0 ? AppColors.primary.withOpacity(0.1) : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _gender == 0 ? AppColors.primary : AppColors.divider)), child: Center(child: Text('Male', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _gender == 0 ? AppColors.primary : AppColors.textDark)))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(onTap: () => setState(() => _gender = 1), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _gender == 1 ? AppColors.primary.withOpacity(0.1) : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _gender == 1 ? AppColors.primary : AppColors.divider)), child: Center(child: Text('Female', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _gender == 1 ? AppColors.primary : AppColors.textDark)))))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Text('Daily Reading Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
            const Spacer(),
            Text('${_dailyGoal}m', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
          Slider(value: _dailyGoal.toDouble(), min: 5, max: 120, divisions: 23, activeColor: AppColors.primary, inactiveColor: AppColors.divider, onChanged: (v) => setState(() => _dailyGoal = v.toInt())),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(_isPrivate ? Icons.lock_rounded : Icons.public_rounded, size: 20, color: AppColors.textGrey),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Private Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text('Hide your stats from other readers', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ])),
              Switch.adaptive(value: _isPrivate, activeColor: AppColors.primary, onChanged: (v) => setState(() => _isPrivate = v)),
            ]),
          ),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }
}
