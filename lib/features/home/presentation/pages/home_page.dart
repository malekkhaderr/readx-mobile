import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/data/book_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _onBooksChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    BookRepository.addListener(_onBooksChanged);
  }

  @override
  void dispose() {
    BookRepository.removeListener(_onBooksChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRead = BookRepository.getCurrentRead();
    final recommended = BookRepository.getRecommended();
    final libraryBooks = BookRepository.getLibraryBooks();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _GreetingHeader(),
              const SizedBox(height: 8),
              _DailyGoalCard(booksRead: libraryBooks.where((b) => b.progress >= 1.0).length),
              const SizedBox(height: 4),
              _StatsRow(
                streakDays: 15,
                booksRead: BookRepository.getCompletedBooksCount(),
              ),
              const SizedBox(height: 4),
              if (currentRead != null)
                _CurrentReadCard(
                  book: currentRead,
                  onContinue: () => context.push('/reader/${currentRead.id}/${currentRead.currentChapter}'),
                ),
              const SizedBox(height: 16),
              _PickedForYouSection(
                books: recommended,
                onBookTap: (book) => context.push('/book/${book.id}'),
              ),
              const SizedBox(height: 16),
              _DailyTipBanner(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting Header ─────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: Image.asset('assets/images/owl.png', width: 44, height: 44, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hoot! ${_getGreeting()}, Alex',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(width: 4),
                    const Text('🌟', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Level 12 Scholar Owl',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications'), duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.notifications_outlined, color: AppColors.textDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily Goal Card ─────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  final int booksRead;
  const _DailyGoalCard({required this.booksRead});

  @override
  Widget build(BuildContext context) {
    const minutesRead = 13;
    const goalMinutes = 30;
    const double progress = minutesRead / goalMinutes;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Reading Goal', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Text('5/7 reached', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('13', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, height: 1)),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('minutes', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                '"What I read today, my future-self thanks me for!"',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int streakDays;
  final int booksRead;
  const _StatsRow({required this.streakDays, required this.booksRead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _StatCard(emoji: '🔥', label: 'DAY STREAK', value: '$streakDays Days'),
          const SizedBox(width: 12),
          _StatCard(emoji: '📚', label: 'BOOKS READ', value: '$booksRead'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  const _StatCard({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Current Read Card ───────────────────────────────────────
class _CurrentReadCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onContinue;
  const _CurrentReadCard({required this.book, this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Current Read', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              GestureDetector(
                onTap: () => context.push('/book/${book.id}'),
                child: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _BookCoverSmall(coverUrl: book.coverUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(book.author, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    const SizedBox(height: 4),
                    Text('Chapter ${book.currentChapter}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: book.progress,
                              minHeight: 5,
                              backgroundColor: AppColors.primaryLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${(book.progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Picked For You ──────────────────────────────────────────
class _PickedForYouSection extends StatelessWidget {
  final List<BookModel> books;
  final void Function(BookModel book) onBookTap;
  const _PickedForYouSection({required this.books, required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Picked for You', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return GestureDetector(
                onTap: () => onBookTap(book),
                child: _BookPickCard(book: book),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookPickCard extends StatelessWidget {
  final BookModel book;
  const _BookPickCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFF7B61FF), const Color(0xFF9D8AFF)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
      [const Color(0xFF4ECDC4), const Color(0xFF6EE7DF)],
      [const Color(0xFFFFB347), const Color(0xFFFFCC70)],
      [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
    ];
    final colorIndex = book.id.hashCode.abs() % colors.length;

    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    book.coverUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: AppColors.primaryLight,
                      child: const Center(child: Icon(Icons.book, color: AppColors.primary)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text('${book.rating}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// ── Shared book cover ───────────────────────────────────────
class _BookCoverSmall extends StatelessWidget {
  final String coverUrl;
  const _BookCoverSmall({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(2, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          coverUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.primaryLight,
            child: const Center(child: Icon(Icons.book, color: AppColors.primary)),
          ),
        ),
      ),
    );
  }
}

// ── Daily Tip ───────────────────────────────────────────────
class _DailyTipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
            child: ClipOval(child: Image.asset('assets/images/owl.png', width: 36, height: 36, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hootie's Daily Tip", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 3),
                Text(
                  'Reading for just 15 minutes before bed can improve your sleep quality by 68%. Try a chapter tonight!',
                  style: TextStyle(fontSize: 11, color: AppColors.textDark.withOpacity(0.7), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
