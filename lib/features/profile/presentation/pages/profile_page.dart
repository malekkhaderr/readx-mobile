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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/di/injection_container.dart';
import 'package:go_router/go_router.dart';

import '../../../author_dashboard/presentation/bloc/author_dashboard_bloc.dart';
import '../../../author_dashboard/presentation/pages/author_book_detail_page.dart';
import '../../../author_dashboard/data/models/author_book_model.dart';

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
    ).whenComplete(() {
      // Dispose the controllers when the sheet closes — otherwise each
      // open-edit cycle leaks two TextEditingControllers permanently.
      nameController.dispose();
      emailController.dispose();
    });
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

    // ── Reader profile (unchanged) ───────────────────────────
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
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profile.avatarImageUrl!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(profile.avatarInitial,
                                    style: const TextStyle(
                                        fontSize: 36,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(profile.avatarInitial,
                                style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
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
                _ActionButton(label: 'My Reports', icon: Icons.report_gmailerrorred_outlined, isPrimary: true, onTap: () {
                  context.push('/reports');
                }),
              ]),
              const SizedBox(height: 8),

              // ── Stats or empty state ───────────────────────
              if (dashboard != null) ...[
                _ProfileStatsRow(dashboard: dashboard),
                if (dashboard.completedBooks.isNotEmpty) _CompletedBooksSection(books: dashboard.completedBooks),
                _ReadingRitualsSection(dashboard: dashboard),
                // Reward Store hidden — backend rewards system is not built yet
                // and the section was using MockShopData. Re-enable when the
                // real /api/rewards endpoint exists.
                // _RewardStoreSection(feathersAvailable: dashboard.cubes),
                _TrophyGridSection(trophies: dashboard.trophies),
              ] else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: const Column(children: [
                    Text('📚', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('Start Your Reading Journey!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark), textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    Text('Your reading stats will appear here as you start reading.', style: TextStyle(fontSize: 13, color: AppColors.textGrey), textAlign: TextAlign.center),
                  ]),
                ),

              const SizedBox(height: 24),

              // ── Logout Button ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
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
                    const Icon(Icons.mail_outline, size: 18, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Please verify your email address.', style: TextStyle(fontSize: 13, color: AppColors.warningOrange, fontWeight: FontWeight.w500))),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent!'))),
                      child: const Text('Resend', style: TextStyle(fontSize: 13, color: AppColors.warningOrange, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),

              // ── Author Info Header Card ────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
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
                                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Profile Info Fields ────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
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
                              child: const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Detailed Statistics', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 2),
                                  Text('View Quotes & Book Stats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    _divider(),
                    InkWell(
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
                              child: const Icon(Icons.report_gmailerrorred_rounded, size: 18, color: AppColors.error),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('My Reports', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 2),
                                  Text('View & Submit Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.error),
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
                  const Text('Published Books', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
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
                          child: Text('$count books', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Column(children: [
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
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => AuthorBookDetailPage(book: book)),
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Books unavailable', style: TextStyle(color: AppColors.textGrey))),
                ),


              const SizedBox(height: 28),

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

  Widget _divider() => const Divider(height: 1, indent: 52);
}

// ── Info Tile (author profile detail row) ─────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

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
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textDark)),
              ],
            ),
          ),
        ],
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
                          style: const TextStyle(
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
                    style: const TextStyle(
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
                      const Icon(Icons.star_rounded, size: 12, color: AppColors.warningOrange),
                      const SizedBox(width: 3),
                      Text(
                        book.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textGrey),
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
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 36),
      ),
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
        _Stat(value: '${dashboard.booksRead}', label: 'Books', icon: const Text('📚', style: TextStyle(fontSize: 18))),
        Container(width: 1, height: 36, color: AppColors.divider),
        _Stat(value: '${dashboard.streakDays}', label: 'Day Streak', icon: const Text('🔥', style: TextStyle(fontSize: 18))),
        Container(width: 1, height: 36, color: AppColors.divider),
        _Stat(
          value: dashboard.formattedCubes,
          label: 'Feathers',
          icon: Image.asset(
            'assets/images/purple_feather.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Widget icon;
  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(height: 22, child: Center(child: icon)),
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
                          ? CachedNetworkImage(
                              imageUrl: book.coverImageUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: AppColors.primaryLight,
                                highlightColor: Colors.white,
                                child: Container(width: 72, height: 72, color: AppColors.primaryLight),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.book, color: AppColors.primary)),
                            )
                          : Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.book, color: AppColors.primary)),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activity.minutesRead > 0 ? AppColors.successGreen : AppColors.primaryLight.withOpacity(0.5),
            border: Border.all(color: activity.minutesRead > 0 ? AppColors.successGreen : AppColors.divider, width: 2),
          ),
          child: Center(
            child: Text(
              activity.minutesRead >= 60
                  ? (activity.minutesRead % 60 == 0
                      ? '${(activity.minutesRead / 60).toInt()}h'
                      : '${(activity.minutesRead / 60).toStringAsFixed(1)}h')
                  : '${activity.minutesRead}m',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: activity.minutesRead > 0 ? Colors.white : AppColors.textGrey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activity.day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: activity.minutesRead > 0 ? AppColors.successGreen : AppColors.textGrey,
          ),
        ),
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
                ? CachedNetworkImage(
                    imageUrl: trophy.iconUrl!,
                    width: 64,
                    height: 64,
                    errorWidget: (_, __, ___) => const Text('🏆', style: TextStyle(fontSize: 48)),
                  )
                : const Text('🏆', style: TextStyle(fontSize: 48)),
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


