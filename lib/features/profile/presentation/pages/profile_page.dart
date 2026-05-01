import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/data/book_repository.dart';
import '../../../../core/data/reading_history_repository.dart';
import '../../data/models/mock_profile_data.dart';
import '../../../shop/data/models/mock_shop_data.dart';
import '../widgets/reward_store_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _selectedAvatar = '👩‍💼';

  static const List<String> _avatarOptions = [
    '👩‍💼', '👨‍💼', '🧑‍🎓', '👩‍🎓', '🧙‍♀️', '🧙‍♂️',
    '🦊', '🐱', '🐶', '🦉', '🐼', '🐨',
    '🧑‍🚀', '👩‍🎨', '🧑‍💻', '👨‍🏫', '🧝‍♀️', '🧝‍♂️',
  ];

  @override
  void initState() {
    super.initState();
    BookRepository.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BookRepository.removeListener(_onDataChanged);
    super.dispose();
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Choose Avatar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('Select a profile avatar or character', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 20),
              // Preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(_selectedAvatar, style: const TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 20),
              // Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: _avatarOptions.length,
                itemBuilder: (c, i) {
                  final av = _avatarOptions[i];
                  final isSelected = av == _selectedAvatar;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {});
                      setState(() => _selectedAvatar = av);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2.5 : 1),
                      ),
                      child: Center(child: Text(av, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated! ✨'), backgroundColor: AppColors.successGreen, duration: Duration(seconds: 1)));
                  },
                  child: const Text('Save Avatar', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadingHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ReadingHistorySheet(),
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: MockProfileData.profile.name);
    final emailController = TextEditingController(text: 'reader@readora.app');
    final goalController = TextEditingController(text: '30');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 20),
            TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 14),
            TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 14),
            TextFormField(controller: goalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily Reading Goal (min)', prefixIcon: Icon(Icons.timer_outlined))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    MockProfileData.updateProfile(name: newName);
                    setState(() {}); // rebuild profile page
                  }
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated! ✅'), backgroundColor: AppColors.successGreen, duration: Duration(seconds: 1)));
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBooks = BookRepository.getLibraryBooks().length;
    final completedBooks = BookRepository.getCompletedBooks();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Avatar with edit badge ─────────────────────
              GestureDetector(
                onTap: _showAvatarPicker,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Text(_selectedAvatar, style: const TextStyle(fontSize: 40))),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(MockProfileData.profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(MockProfileData.profile.level, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),

              // ── Action buttons ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(label: 'Edit Profile', icon: Icons.edit_outlined, onTap: _showEditProfile),
                  const SizedBox(width: 10),
                  _ActionButton(label: 'Summaries', icon: Icons.summarize_outlined, isPrimary: true, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading summaries coming soon!'), duration: Duration(seconds: 1)));
                  }),
                ],
              ),
              const SizedBox(height: 8),

              // ── Stats ──────────────────────────────────────
              _ProfileStatsRow(profile: MockProfileData.profile, totalBooks: totalBooks),

              // ── Completed Books ────────────────────────────
              if (completedBooks.isNotEmpty) _CompletedBooksSection(books: completedBooks),

              // ── Reading Rituals ────────────────────────────
              _ReadingRitualsSection(rituals: MockProfileData.weeklyRituals, onViewHistory: _showReadingHistory),

              // ── Reward Store ──────────────────────────────
              _RewardStoreSection(
                cubeBalance: MockProfileData.profile.cubes,
                rewardItems: MockShopData.featuredRewards,
                onOpenStore: () => showRewardStoreSheet(context),
              ),

              // ── Trophies ───────────────────────────────────
              _TrophyGridSection(trophies: MockProfileData.trophies),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Button ───────────────────────────────────────────
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

// ── Stats Row ───────────────────────────────────────────────
class _ProfileStatsRow extends StatelessWidget {
  final MockUserProfile profile;
  final int totalBooks;
  const _ProfileStatsRow({required this.profile, required this.totalBooks});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _Stat(value: '$totalBooks', label: 'Books', emoji: '📚'),
        Container(width: 1, height: 36, color: AppColors.divider),
        _Stat(value: '${profile.streakDays}', label: 'Day Streak', emoji: '🔥'),
        Container(width: 1, height: 36, color: AppColors.divider),
        _Stat(value: profile.cubes >= 1000 ? '${(profile.cubes / 1000).toStringAsFixed(1)}k' : '${profile.cubes}', label: 'Cubes', emoji: '🧊'),
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

// ── Completed Books Section ─────────────────────────────────
class _CompletedBooksSection extends StatelessWidget {
  final List<BookModel> books;
  const _CompletedBooksSection({required this.books});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                final colors = [
                  [const Color(0xFF7B61FF), const Color(0xFF9D8AFF)],
                  [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
                  [const Color(0xFF4ECDC4), const Color(0xFF6EE7DF)],
                  [const Color(0xFFFFB347), const Color(0xFFFFCC70)],
                  [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
                ];
                final ci = book.id.hashCode.abs() % colors.length;
                return Container(
                  width: 80,
                  margin: EdgeInsets.only(right: index < books.length - 1 ? 12 : 0),
                  child: Column(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              book.coverUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: AppColors.primaryLight,
                                child: const Center(child: Icon(Icons.book, color: AppColors.primary, size: 20)),
                              ),
                            ),
                          ),
                          Positioned(bottom: 4, right: 4, child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          )),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reading Rituals ─────────────────────────────────────────
class _ReadingRitualsSection extends StatelessWidget {
  final List<ReadingRitual> rituals;
  final VoidCallback onViewHistory;
  const _ReadingRitualsSection({required this.rituals, required this.onViewHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Reading Rituals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            GestureDetector(
              onTap: onViewHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: const Text('VIEW HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
            const SizedBox(width: 4),
            const Text(MockProfileData.totalReadingTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(width: 16),
            const Icon(Icons.trending_up, size: 14, color: AppColors.successGreen),
            const SizedBox(width: 4),
            const Text(MockProfileData.avgSessionTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: rituals.map((r) => _RitualDay(ritual: r)).toList()),
        ],
      ),
    );
  }
}

class _RitualDay extends StatelessWidget {
  final ReadingRitual ritual;
  const _RitualDay({required this.ritual});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ritual.day}: ${ritual.minutesRead} minutes read'), duration: const Duration(seconds: 1))),
      child: Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: ritual.completed ? AppColors.primary : AppColors.primaryLight.withOpacity(0.5), border: Border.all(color: ritual.completed ? AppColors.primary : AppColors.divider, width: 2)),
          child: Center(child: ritual.completed ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${ritual.minutesRead}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
        ),
        const SizedBox(height: 4),
        Text(ritual.day, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ritual.completed ? AppColors.primary : AppColors.textGrey)),
      ]),
    );
  }
}

// ── Reward Store Section ────────────────────────────────────
class _RewardStoreSection extends StatelessWidget {
  final int cubeBalance;
  final List<ShopItem> rewardItems;
  final VoidCallback onOpenStore;
  const _RewardStoreSection({required this.cubeBalance, required this.rewardItems, required this.onOpenStore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reward Store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              GestureDetector(
                onTap: onOpenStore,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const Text('OPEN STORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini wallet card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Text('🧊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cubeBalance >= 1000 ? '${(cubeBalance / 1000).toStringAsFixed(1)}k' : '$cubeBalance',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1),
                    ),
                    Text('Cubes Available', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onOpenStore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Text('View Rewards', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preview items
          Row(
            children: rewardItems.take(3).map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: onOpenStore,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🧊', style: TextStyle(fontSize: 8)),
                            const SizedBox(width: 2),
                            Text('${item.price}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Trophy Grid ─────────────────────────────────────────────
class _TrophyGridSection extends StatelessWidget {
  final List<Trophy> trophies;
  const _TrophyGridSection({required this.trophies});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Trophies & Runes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: trophies.map((t) => _TrophyItem(trophy: t)).toList()),
      ]),
    );
  }
}

class _TrophyItem extends StatelessWidget {
  final Trophy trophy;
  const _TrophyItem({required this.trophy});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(trophy.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(trophy.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(trophy.unlocked ? 'Achievement unlocked! 🎉' : 'Keep reading to unlock this trophy!', style: const TextStyle(color: AppColors.textGrey, fontSize: 13), textAlign: TextAlign.center),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        ),
      ),
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: trophy.unlocked ? AppColors.primaryLight : AppColors.divider.withOpacity(0.5), border: Border.all(color: trophy.unlocked ? AppColors.primary.withOpacity(0.3) : AppColors.divider, width: 2)),
          child: Center(child: Text(trophy.emoji, style: TextStyle(fontSize: 22, color: trophy.unlocked ? null : Colors.grey))),
        ),
        const SizedBox(height: 4),
        Text(trophy.name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: trophy.unlocked ? AppColors.textDark : AppColors.textGrey)),
      ]),
    );
  }
}

// ── Reading History Sheet ───────────────────────────────────
class _ReadingHistorySheet extends StatelessWidget {
  final List<String> _dayNames = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${_dayNames[dt.weekday - 1]}, ${diff} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final history = ReadingHistoryRepository.getHistory();
    final stats = ReadingHistoryRepository.getStats();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Reading History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _HistoryStat(label: 'Total Time', value: '${(stats['totalMinutes'] as int) ~/ 60}h ${(stats['totalMinutes'] as int) % 60}m', emoji: '⏱️'),
              const SizedBox(width: 10),
              _HistoryStat(label: 'Sessions', value: '${stats['totalSessions']}', emoji: '📖'),
              const SizedBox(width: 10),
              _HistoryStat(label: 'Goals Met', value: '${stats['goalsReached']}', emoji: '🎯'),
              const SizedBox(width: 10),
              _HistoryStat(label: 'Avg/Day', value: '${stats['avgMinutesPerDay']}m', emoji: '📊'),
            ]),
          ),
          const SizedBox(height: 16),

          // Daily list
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final day = history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(_formatDate(day.date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: day.goalReached ? AppColors.successGreen.withOpacity(0.15) : (day.totalMinutes > 0 ? AppColors.warningOrange.withOpacity(0.15) : AppColors.divider.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            day.goalReached ? '✅ Goal Reached' : (day.totalMinutes > 0 ? '${day.totalMinutes}m' : 'Rest Day'),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: day.goalReached ? AppColors.successGreen : (day.totalMinutes > 0 ? AppColors.warningOrange : AppColors.textGrey)),
                          ),
                        ),
                      ]),
                      if (day.totalMinutes > 0) ...[
                        const SizedBox(height: 6),
                        Text('${day.totalMinutes} min • ${day.sessions} session${day.sessions > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        if (day.sessionDetails.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...day.sessionDetails.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  s.coverUrl,
                                  width: 16,
                                  height: 22,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.book, size: 16, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.bookTitle, style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500))),
                              Text('${s.minutesRead}m · ${s.pagesRead} pg', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                            ]),
                          )),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  final String label, value, emoji;
  const _HistoryStat({required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
        ]),
      ),
    );
  }
}
