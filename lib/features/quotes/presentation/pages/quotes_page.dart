import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/data/quotes_repository.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  String _filter = 'All';

  List<SavedQuote> get _filteredQuotes {
    final all = QuotesRepository.getAllQuotes();
    if (_filter == 'All') return all;
    return all.where((q) => q.bookTitle == _filter).toList();
  }

  List<String> get _bookFilters {
    final books = QuotesRepository.getAllQuotes().map((q) => q.bookTitle).toSet().toList();
    books.sort();
    return ['All', ...books];
  }

  void _deleteQuote(SavedQuote quote) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('"${quote.text.length > 60 ? '${quote.text.substring(0, 60)}...' : quote.text}"', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textGrey, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textGrey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              QuotesRepository.removeQuote(quote.id);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote deleted'), duration: Duration(seconds: 1)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _filteredQuotes;
    final filters = _bookFilters;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quotes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        SizedBox(height: 2),
                        Text('Your saved highlights', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('${QuotesRepository.count}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Book filter chips
            if (filters.length > 1)
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final f = filters[index];
                    final isSelected = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: AppColors.divider),
                          ),
                          child: Text(f == 'All' ? 'All Books' : f, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textGrey)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Quotes list
            Expanded(
              child: quotes.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle), child: const Center(child: Text('💬', style: TextStyle(fontSize: 36)))),
                        const SizedBox(height: 16),
                        const Text('No quotes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 8),
                        const Text('Save quotes while reading to\nsee them here', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4)),
                      ]),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: quotes.length,
                      itemBuilder: (context, index) => _QuoteCard(quote: quotes[index], onDelete: () => _deleteQuote(quotes[index])),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quote Card ──────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final SavedQuote quote;
  final VoidCallback onDelete;
  const _QuoteCard({required this.quote, required this.onDelete});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote text
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
            ),
            child: Text(quote.text, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textDark, height: 1.5, fontFamily: 'Georgia')),
          ),
          const SizedBox(height: 12),
          // Book info row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  quote.coverUrl,
                  width: 24,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.book, size: 24, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quote.bookTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    Text('${quote.chapterTitle} • ${_timeAgo(quote.savedAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
              ),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
