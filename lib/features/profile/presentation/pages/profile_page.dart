import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../shop/data/models/mock_shop_data.dart';
import '../widgets/reward_store_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/di/injection_container.dart';
import 'package:go_router/go_router.dart';

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
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
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
          const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.textGrey)),
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
  void _showEditProfile() {
    final nameController = TextEditingController(text: widget.profile.fullName);
    final emailController = TextEditingController(text: widget.profile.email);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 20),
          TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile update coming soon!'), duration: Duration(seconds: 1)));
              },
              child: const Text('Save Changes'),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.warningOrange.withOpacity(0.15),
                  child: Row(children: [
                    const Icon(Icons.mail_outline, size: 18, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Please verify your email address.', style: TextStyle(fontSize: 13, color: AppColors.warningOrange, fontWeight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent!'))),
                      child: const Text('Resend', style: TextStyle(fontSize: 13, color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),

              const SizedBox(height: 20),

              // ── Avatar ────────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: profile.hasAvatar
                        ? ClipOval(child: Image.network(profile.avatarImageUrl!, width: 90, height: 90, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Text(profile.avatarInitial, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)))))
                        : Center(child: Text(profile.avatarInitial, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Text(profile.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              if (dashboard != null)
                Text(dashboard.levelLabel, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),

              // ── Action buttons ─────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ActionButton(label: 'Edit Profile', icon: Icons.edit_outlined, onTap: _showEditProfile),
                const SizedBox(width: 10),
                _ActionButton(label: 'Summaries', icon: Icons.summarize_outlined, isPrimary: true, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading summaries coming soon!'), duration: Duration(seconds: 1)));
                }),
              ]),
              const SizedBox(height: 8),

              // ── Stats or empty state ───────────────────────
              if (dashboard != null) ...[
                _ProfileStatsRow(dashboard: dashboard),
                if (dashboard.completedBooks.isNotEmpty) _CompletedBooksSection(books: dashboard.completedBooks),
                _ReadingRitualsSection(dashboard: dashboard),
                _RewardStoreSection(cubesAvailable: dashboard.cubes),
                _TrophyGridSection(trophies: dashboard.trophies),
              ] else
                _EmptyDashboard(profile: profile),

              const SizedBox(height: 24),

              // ── Logout Button ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Trigger logout event
                    context.read<AuthBloc>().add(const LogoutEvent());
                  },
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

// ── Empty Dashboard (new user / author) ─────────────────────
class _EmptyDashboard extends StatelessWidget {
  final UserProfileEntity profile;
  const _EmptyDashboard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        const Text('📚', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(profile.isAuthor ? 'Author Dashboard' : 'Start Your Reading Journey!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(profile.isAuthor ? 'Author stats will appear here once available.' : 'Your reading stats will appear here as you start reading.',
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Action Button ────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, this.isPrimary = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.divider),
          boxShadow: isPrimary ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: isPrimary ? Colors.white : AppColors.textDark),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPrimary ? Colors.white : AppColors.textDark)),
        ]),
      ),
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────
class _ProfileStatsRow extends StatelessWidget {
  final ReaderDashboardEntity dashboard;
  const _ProfileStatsRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _Stat(value: '${dashboard.booksRead}', label: 'Books', emoji: '📚'),
        Container(width: 1, height: 36, color: AppColors.divider),
        _Stat(value: '${dashboard.streakDays}', label: 'Day Streak', emoji: '🔥'),
        Container(width: 1, height: 36, color: AppColors.divider),
        _Stat(value: dashboard.formattedCubes, label: 'Cubes', emoji: '🧊'),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label, emoji;
  const _Stat({required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
  ]);
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Completed Books', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.successGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${books.length} books', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successGreen)),
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
                          ? Image.network(book.coverImageUrl!, width: 72, height: 72, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: AppColors.primaryLight, child: const Icon(Icons.book, color: AppColors.primary)))
                          : Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.book, color: AppColors.primary)),
                    ),
                    Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 10))),
                  ]),
                  const SizedBox(height: 6),
                  Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Reading Rituals ──────────────────────────────────────────
class _ReadingRitualsSection extends StatelessWidget {
  final ReaderDashboardEntity dashboard;
  const _ReadingRitualsSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Reading Rituals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 4),
          Text(dashboard.totalReadingTime, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(width: 16),
          const Icon(Icons.trending_up, size: 14, color: AppColors.successGreen),
          const SizedBox(width: 4),
          Text('${dashboard.dailyGoal}m goal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 14),
        dashboard.weeklyRituals.isEmpty
            ? const Text('No weekly activity yet.', style: TextStyle(fontSize: 12, color: AppColors.textGrey))
            : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: dashboard.weeklyRituals.map((r) => _RitualDay(activity: r)).toList()),
      ]),
    );
  }
}

class _RitualDay extends StatelessWidget {
  final DayActivityEntity activity;
  const _RitualDay({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${activity.day}: ${activity.minutesRead} minutes read'), duration: const Duration(seconds: 1))),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: activity.completed ? AppColors.primary : AppColors.primaryLight.withOpacity(0.5), border: Border.all(color: activity.completed ? AppColors.primary : AppColors.divider, width: 2)),
          child: Center(child: activity.completed ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${activity.minutesRead}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
        ),
        const SizedBox(height: 4),
        Text(activity.day, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: activity.completed ? AppColors.primary : AppColors.textGrey)),
      ]),
    );
  }
}

// ── Reward Store ─────────────────────────────────────────────
class _RewardStoreSection extends StatelessWidget {
  final int cubesAvailable;
  const _RewardStoreSection({required this.cubesAvailable});

  String get _formattedCubes => cubesAvailable >= 1000 ? '${(cubesAvailable / 1000).toStringAsFixed(1)}k' : '$cubesAvailable';

  @override
  Widget build(BuildContext context) {
    final rewardItems = MockShopData.featuredRewards;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Reward Store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          GestureDetector(
            onTap: () => showRewardStoreSheet(context),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)), child: const Text('OPEN STORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5))),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(children: [
            const Text('🧊', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_formattedCubes, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1)),
              Text('Cubes Available', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () => showRewardStoreSheet(context),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Text('View Rewards', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: rewardItems.take(3).map((item) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: () => showRewardStoreSheet(context),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.4), borderRadius: BorderRadius.circular(12)), child: Column(children: [
              Text(item.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [const Text('🧊', style: TextStyle(fontSize: 8)), const SizedBox(width: 2), Text('${item.price}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary))]),
            ])),
          ),
        ))).toList()),
      ]),
    );
  }
}

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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Trophies & Runes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
                ? Image.network(trophy.iconUrl!, width: 64, height: 64, errorBuilder: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 48)))
                : const Text('🏆', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(trophy.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(trophy.earned ? 'Achievement unlocked! 🎉' : 'Keep reading to unlock this trophy!', style: const TextStyle(color: AppColors.textGrey, fontSize: 13), textAlign: TextAlign.center),
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
                ? ClipOval(child: Image.network(trophy.iconUrl!, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text('🏆', style: TextStyle(fontSize: 22, color: trophy.earned ? null : Colors.grey))))
                : Text('🏆', style: TextStyle(fontSize: 22, color: trophy.earned ? null : Colors.grey)),
          ),
        ),
        const SizedBox(height: 4),
        Text(trophy.name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: trophy.earned ? AppColors.textDark : AppColors.textGrey)),
      ]),
    );
  }
}
