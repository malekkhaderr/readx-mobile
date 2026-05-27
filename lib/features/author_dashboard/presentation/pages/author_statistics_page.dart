import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../bloc/author_dashboard_bloc.dart';
import '../widgets/author_book_reviews_sheet.dart';
import '../../data/models/author_book_model.dart';

class AuthorStatisticsPage extends StatefulWidget {
  const AuthorStatisticsPage({super.key});

  @override
  State<AuthorStatisticsPage> createState() => _AuthorStatisticsPageState();
}

class _AuthorStatisticsPageState extends State<AuthorStatisticsPage> {
  @override
  void initState() {
    super.initState();
    // Load statistics when page is opened
    context.read<AuthorDashboardBloc>().add(const LoadAuthorStatisticsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<AuthorDashboardBloc>().add(const LoadAuthorStatisticsEvent());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: BlocBuilder<AuthorDashboardBloc, AuthorDashboardState>(
              builder: (context, state) {
                final bloc = context.read<AuthorDashboardBloc>();
                final stats = bloc.cachedStatistics;

                if ((state is AuthorStatisticsLoading || state is AuthorDashboardInitial) && stats == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (state is AuthorStatisticsError && stats == null) {
                  return Center(child: Text(state.message, style: const TextStyle(color: AppColors.error)));
                }

                if (stats != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview
                      _buildOverviewCard(stats, state is AuthorStatisticsLoaded ? state.quotesStats : null),
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Per Book Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (stats.bookStatistics.isEmpty)
                        const Center(child: Text('No book statistics available', style: TextStyle(color: AppColors.textGrey)))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stats.bookStatistics.length,
                          itemBuilder: (context, index) {
                            return _buildBookStatCard(
                              stats.bookStatistics[index],
                              state is AuthorStatisticsLoaded ? state.quotesStats : null,
                              bloc.cachedBooks,
                            );
                          },
                        ),
                    ],
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(dynamic stats, dynamic quotesStats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Impact',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn(Icons.visibility, stats.totalViews.toString(), 'Views'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMetricColumn(Icons.auto_stories, stats.totalReads.toString(), 'Reads'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMetricColumn(Icons.star, stats.averageRating.toStringAsFixed(1), 'Rating'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildMetricColumn(Icons.format_quote_rounded, quotesStats?.totalQuotesCount.toString() ?? '-', 'Quotes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBookStatCard(dynamic bookStat, dynamic quotesStats, List<AuthorBook>? cachedBooks) {
    int quotesCount = 0;
    if (quotesStats != null) {
      final q = quotesStats.bookQuoteCounts.where((b) => b.bookId == bookStat.bookId).toList();
      if (q.isNotEmpty) quotesCount = q.first.quotesCount;
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          AuthorBook? authorBook;
          if (cachedBooks != null) {
            for (final b in cachedBooks) {
              if (b.id == bookStat.bookId) {
                authorBook = b;
                break;
              }
            }
          }

          if (authorBook != null) {
            context.push('/author/book_detail', extra: {
              'book': authorBook,
              'quotesCount': quotesCount,
            });
          } else {
            // Fallback if not in cache
            context.push('/book/${bookStat.bookId}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookStat.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallStat(Icons.visibility_rounded, bookStat.viewCount.toString(), 'Views'),
                  _buildSmallStat(Icons.auto_stories_rounded, bookStat.readCount.toString(), 'Reads'),
                  _buildSmallStat(Icons.star_rounded, bookStat.averageRating.toStringAsFixed(1), 'Rating'),
                  _buildSmallStat(Icons.format_quote_rounded, quotesCount.toString(), 'Quotes'),
                  _buildSmallStat(Icons.comment_rounded, bookStat.ratingsCount.toString(), 'Ratings', onTap: () {
                    AuthorBookReviewsSheet.show(context, bookStat.bookId, bookStat.title);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSmallStat(IconData icon, String value, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryLight),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
