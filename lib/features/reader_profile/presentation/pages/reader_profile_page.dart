import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/reader_profile_remote_datasource.dart';
import '../../../levels/data/datasources/levels_remote_datasource.dart';
import '../../../levels/data/models/reader_level_model.dart';
import '../../../quotes/data/models/quote_model.dart';

class ReaderProfilePage extends StatefulWidget {
  final int userId;
  const ReaderProfilePage({super.key, required this.userId});

  @override
  State<ReaderProfilePage> createState() => _ReaderProfilePageState();
}

class _ReaderProfilePageState extends State<ReaderProfilePage> with TickerProviderStateMixin {
  ReaderProfileData? _profile;
  List<ReaderLevel> _levels = [];
  List<QuoteDetails> _quotes = [];
  bool _loading = true;
  bool _loadingQuotes = false;
  String? _error;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profileDs = ReaderProfileRemoteDataSource(dioClient: sl());
      final levelsDs = LevelsRemoteDataSource(dioClient: sl());
      final results = await Future.wait([
        profileDs.getReaderProfile(widget.userId),
        levelsDs.getAllLevels(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as ReaderProfileData;
          _levels = (results[1] as List<ReaderLevel>)..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
          _loading = false;
        });
        if (!_profile!.isPrivateProfile) _loadQuotes();
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load profile'; _loading = false; });
    }
  }

  Future<void> _loadQuotes() async {
    setState(() => _loadingQuotes = true);
    try {
      final response = await sl<DioClient>().dio.get('/quotes', queryParameters: {'readerUserId': widget.userId, 'pageNumber': 1, 'pageSize': 20});
      if (response.statusCode == 200) {
        final data = response.data;
        final items = data is Map ? (data['items'] as List? ?? []) : [];
        _quotes = items.map((e) => QuoteDetails.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingQuotes = false);
  }

  ReaderLevel? get _currentLevel {
    if (_profile?.levelId == null) return _levels.isNotEmpty ? _levels.first : null;
    return _levels.where((l) => l.id == _profile!.levelId).firstOrNull ?? (_levels.isNotEmpty ? _levels.first : null);
  }

  ReaderLevel? get _nextLevel {
    final current = _currentLevel;
    if (current == null) return null;
    final idx = _levels.indexOf(current);
    return idx < _levels.length - 1 ? _levels[idx + 1] : null;
  }

  double get _levelProgress {
    final current = _currentLevel;
    final next = _nextLevel;
    final tokens = _profile?.totalTokensEarned ?? 0;
    if (current == null || next == null) return next == null && current != null ? 1.0 : 0.0;
    final range = next.minTokens - current.minTokens;
    return range > 0 ? ((tokens - current.minTokens) / range).clamp(0.0, 1.0) : 1.0;
  }

  String _lastActive() {
    final date = _profile?.lastReadDate;
    if (date == null) return 'Never';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 5) return 'Active now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final profile = _profile!;
    final level = _currentLevel;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // ── Gradient Hero Header ──
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.surface,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroHeader(profile, level),
          ),
        ),
        // ── Tab Bar ──
        if (!profile.isPrivateProfile)
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textGrey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Quotes'),
                  Tab(text: 'Books'),
                ],
              ),
              backgroundColor: AppColors.surface,
            ),
          ),
      ],
      body: profile.isPrivateProfile
          ? _buildPrivateCard(profile)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(profile, level),
                _buildQuotesTab(),
                _buildBooksTab(profile),
              ],
            ),
    );
  }

  Widget _buildHeroHeader(ReaderProfileData profile, ReaderLevel? level) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            // Avatar
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                child: profile.avatarImageUrl != null && profile.avatarImageUrl!.isNotEmpty
                    ? ClipOval(child: CachedNetworkImage(imageUrl: profile.avatarImageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => _avatarFallback(profile.initial)))
                    : _avatarFallback(profile.initial),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(profile.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            // Level + last active
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (level != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.25))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${level.name} • Lvl ${level.levelNumber}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.9))),
                  ]),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 6, color: _profile?.lastReadDate != null && DateTime.now().difference(_profile!.lastReadDate!).inHours < 24 ? Colors.greenAccent : Colors.white38),
                  const SizedBox(width: 5),
                  Text(_lastActive(), style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── OVERVIEW TAB ──
  Widget _buildOverviewTab(ReaderProfileData profile, ReaderLevel? level) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Level progress
        if (level != null) _buildLevelCard(level),
        const SizedBox(height: 16),
        // Stats grid
        Row(children: [
          _StatTile(icon: Icons.schedule_rounded, value: profile.formattedReadingTime, label: 'Reading Time', color: AppColors.primary),
          const SizedBox(width: 10),
          _StatTile(icon: Icons.menu_book_rounded, value: '${profile.booksReadCount ?? 0}', label: 'Books Read', color: AppColors.successGreen),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatTile(icon: Icons.local_fire_department_rounded, value: '${profile.currentStreak ?? 0}', label: 'Current Streak', color: AppColors.warningOrange),
          const SizedBox(width: 10),
          _StatTile(icon: Icons.emoji_events_rounded, value: '${profile.longestStreak ?? 0}', label: 'Best Streak', color: AppColors.gold),
        ]),
        const SizedBox(height: 16),
        // Tokens earned
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.8),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.toll_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${profile.totalTokensEarned ?? 0}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Text('Lifetime Tokens Earned', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLevelCard(ReaderLevel level) {
    final isMax = _nextLevel == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.workspace_premium_rounded, size: 20, color: Colors.white.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(level.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          Text('Lvl ${level.levelNumber}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          Container(height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(3))),
          FractionallySizedBox(
            widthFactor: _levelProgress,
            child: Container(height: 6, decoration: BoxDecoration(
              color: isMax ? Colors.amber : Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 4)],
            )),
          ),
        ]),
        const SizedBox(height: 6),
        Text(isMax ? 'Max Level' : '${(_levelProgress * 100).toInt()}% to ${_nextLevel!.name}', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
      ]),
    );
  }

  // ── QUOTES TAB ──
  Widget _buildQuotesTab() {
    if (_loadingQuotes) return const Center(child: CircularProgressIndicator());
    if (_quotes.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.format_quote_rounded, size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text('No public quotes yet', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _quotes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final q = _quotes[i];
        var text = q.content;
        if (text.startsWith('"') && text.endsWith('"')) text = text.substring(1, text.length - 1);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.8),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 3, height: 30, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textDark, height: 1.5, fontFamily: 'Georgia'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.menu_book_rounded, size: 12, color: AppColors.textGrey),
              const SizedBox(width: 5),
              Expanded(child: Text(q.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500))),
              Text('p.${q.pageNumber}', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
            ]),
          ]),
        );
      },
    );
  }

  // ── BOOKS TAB ──
  Widget _buildBooksTab(ReaderProfileData profile) {
    final books = profile.completedBooks;
    if (books.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.library_books_rounded, size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text('No completed books yet', style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        return GestureDetector(
          onTap: () => context.push('/book/${book.bookId}'),
          child: Column(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: book.coverImageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => _bookFallback())
                      : _bookFallback(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ]),
        );
      },
    );
  }

  // ── PRIVATE CARD ──
  Widget _buildPrivateCard(ReaderProfileData profile) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: AppColors.cardBackground, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
            child: Icon(Icons.lock_rounded, size: 28, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          Text('Private Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('${profile.firstName} has chosen to keep their reading activity private.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5)),
        ]),
      ),
    ));
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.cardBackground, shape: BoxShape.circle), child: Icon(Icons.person_off_rounded, size: 32, color: AppColors.textGrey)),
        const SizedBox(height: 16),
        Text('Profile Not Available', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 8),
        Text('This profile could not be loaded.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Go Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
    ));
  }

  Widget _avatarFallback(String initial) => Center(child: Text(initial, style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.bold)));
  Widget _bookFallback() => Container(color: AppColors.primaryLight, child: Center(child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24)));
}

// ── Stat Tile ──
class _StatTile extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _StatTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 0.8),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ]),
      ]),
    ));
  }
}

// ── Tab Bar Delegate ──
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  _TabBarDelegate({required this.tabBar, required this.backgroundColor});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
