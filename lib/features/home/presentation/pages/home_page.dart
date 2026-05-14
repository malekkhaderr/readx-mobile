import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../../data/models/home_response_model.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _onRefresh() async {
    context.read<HomeBloc>().add(const RefreshHomeEvent());
  }

  @override
  Widget build(BuildContext context) {
    // Read profile data from the shared ProfileBloc
    final profileState = context.watch<ProfileBloc>().state;
    final UserProfileEntity? profile =
        profileState is ProfileLoaded ? profileState.profile : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _GreetingHeader(profile: profile),
                const SizedBox(height: 16),
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading && state.isFirstFetch) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    } else if (state is HomeError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 48),
                              const SizedBox(height: 16),
                              Text(state.message,
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(color: AppColors.textGrey)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _onRefresh,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (state is HomeLoaded) {
                      final data = state.data;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.trendingBooks.isNotEmpty) ...[
                            _BookHorizontalList(
                              title: 'Trending Now',
                              books: data.trendingBooks,
                              onBookTap: (bookId) =>
                                  context.push('/book/$bookId'),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (data.recommendedBooks.isNotEmpty) ...[
                            _BookHorizontalList(
                              title: 'Recommended for You',
                              books: data.recommendedBooks,
                              onBookTap: (bookId) =>
                                  context.push('/book/$bookId'),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (data.newlyAddedBooks.isNotEmpty) ...[
                            _BookHorizontalList(
                              title: 'Newly Added',
                              books: data.newlyAddedBooks,
                              onBookTap: (bookId) =>
                                  context.push('/book/$bookId'),
                            ),
                            const SizedBox(height: 24),
                          ],
                          _DailyTipBanner(),
                          const SizedBox(height: 24),
                          if (data.categories.isNotEmpty) ...[
                            ...data.categories.map((category) {
                              if (category.books.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: _BookHorizontalList(
                                  title: category.categoryName,
                                  books: category.books,
                                  onBookTap: (bookId) =>
                                      context.push('/book/$bookId'),
                                ),
                              );
                            }),
                          ],
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Greeting Header ─────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final UserProfileEntity? profile;
  const _GreetingHeader({this.profile});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = profile?.firstName ?? '';
    final levelLabel = profile?.readerDashboard?.levelLabel ?? '';
    final hasAvatar = profile?.hasAvatar ?? false;
    final avatarUrl = profile?.avatarImageUrl;
    final avatarInitial = profile?.avatarInitial ?? '?';

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
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: hasAvatar
                ? ClipOval(
                    child: Image.network(avatarUrl!,
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                            child: Text(avatarInitial,
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)))),
                  )
                : ClipOval(
                    child: Image.asset('assets/images/owl.png',
                        width: 44, height: 44, fit: BoxFit.cover),
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
                        firstName.isNotEmpty
                            ? 'Hoot! ${_getGreeting()}, $firstName'
                            : 'Hoot! ${_getGreeting()}!',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🌟', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  levelLabel.isNotEmpty ? levelLabel : 'Reader',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('No new notifications'),
                    duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.textDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dynamic Book List ─────────────────────────────────────────
class _BookHorizontalList extends StatelessWidget {
  final String title;
  final List<BookCard> books;
  final void Function(int bookId) onBookTap;

  const _BookHorizontalList({
    required this.title,
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out unpublished books
    final publishedBooks = books.where((b) => b.isPublished).toList();

    if (publishedBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280, // Increased height for rectangular cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: publishedBooks.length,
            itemBuilder: (context, index) {
              final book = publishedBooks[index];
              return GestureDetector(
                onTap: () => onBookTap(book.id),
                child: _BookListCard(book: book),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookListCard extends StatelessWidget {
  final BookCard book;

  const _BookListCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170, // Rectangular aspect ratio for book covers
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: book.coverImageUrl.isNotEmpty
                      ? FutureBuilder<dynamic>(
                          future: () async {
                            try {
                              // 1. Try the primary URL
                              final response = await sl<DioClient>().dio.get<List<int>>(
                                book.coverImageUrl,
                                options: Options(
                                  responseType: ResponseType.bytes,
                                  sendTimeout: const Duration(seconds: 2),
                                  receiveTimeout: const Duration(seconds: 2),
                                ),
                              );
                              if (response.statusCode == 200) return book.coverImageUrl;
                            } catch (_) {
                              // Fail silently and try fallback
                            }

                            // 2. Fallback: Search Google Books API by title
                            try {
                              final query = Uri.encodeComponent(book.title);
                              final searchRes = await Dio().get(
                                'https://www.googleapis.com/books/v1/volumes?q=intitle:$query&maxResults=1',
                              );
                              if (searchRes.data['items'] != null && 
                                  searchRes.data['items'].isNotEmpty) {
                                final volumeInfo = searchRes.data['items'][0]['volumeInfo'];
                                final imageLinks = volumeInfo['imageLinks'];
                                if (imageLinks != null) {
                                  return (imageLinks['thumbnail'] ?? imageLinks['smallThumbnail']);
                                }
                              }
                            } catch (_) {}
                            
                            return null;
                          }(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final imageUrl = snapshot.data as String;
                              return Image.network(
                                imageUrl,
                                width: 120,
                                height: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: AppColors.primaryLight,
                                  child: const Center(
                                      child: Icon(Icons.book,
                                          color: AppColors.primary)),
                                ),
                              );
                            }
                            
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Shimmer.fromColors(
                                baseColor: AppColors.primaryLight,
                                highlightColor: Colors.white,
                                child: Container(
                                  width: 120,
                                  height: 170,
                                  color: AppColors.primaryLight,
                                ),
                              );
                            }

                            return Container(
                              color: AppColors.primaryLight,
                              child: const Center(
                                  child: Icon(Icons.book,
                                      color: AppColors.primary)),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Center(
                              child: Icon(Icons.book, color: AppColors.primary)),
                        ),
                ),
                if (book.viewCount > 0)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '${book.viewCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            book.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  book.categoryName,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${book.totalPages} pages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
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
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle),
            child: ClipOval(
                child: Image.asset('assets/images/owl.png',
                    width: 36, height: 36, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hootie's Daily Tip",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 3),
                Text(
                  'Reading for just 15 minutes before bed can improve your sleep quality by 68%. Try a chapter tonight!',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDark.withOpacity(0.7),
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
