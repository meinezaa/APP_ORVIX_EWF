import 'package:flutter/material.dart';

import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/market_news_service.dart';
import 'market_news_detail.dart';

class MarketNewsListScreen extends StatefulWidget {
  const MarketNewsListScreen({super.key});

  @override
  State<MarketNewsListScreen> createState() => _MarketNewsListScreenState();
}

class _MarketNewsListScreenState extends State<MarketNewsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MarketNewsArticle> _articles = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';
  String? _requestedLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_requestedLanguageCode == languageCode) return;
    _requestedLanguageCode = languageCode;
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final articles = await MarketNewsService.fetchLatest(
        languageCode: _requestedLanguageCode ?? 'id',
      );
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
        _selectedCategory = 'All';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            '${AppStrings.text(context, 'Berita terbaru gagal dimuat.')} $error';
      });
    }
  }

  List<String> get _categories {
    final categories = _articles
        .map((article) => article.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    return ['All', ...categories];
  }

  List<MarketNewsArticle> get _visibleArticles {
    final query = _searchController.text.trim().toLowerCase();
    return _articles.where((article) {
      final matchesCategory =
          _selectedCategory == 'All' || article.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          article.title.toLowerCase().contains(query) ||
          article.summary.toLowerCase().contains(query) ||
          article.category.toLowerCase().contains(query) ||
          article.source.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openArticle(MarketNewsArticle article) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MarketNewsDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleArticles = _visibleArticles;
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.text(context, 'Kembali'),
                      onPressed: () => Navigator.pop(context),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.text(context, 'Discover'),
                            style: TextStyle(
                              color: AppTheme.text(context),
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            AppStrings.text(
                              context,
                              'News from all around the market',
                            ),
                            style: TextStyle(
                              color: AppTheme.mutedText(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.text(context, 'Perbarui berita'),
                      onPressed: _loadArticles,
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: AppTheme.text(context)),
                  decoration: InputDecoration(
                    hintText: AppStrings.text(context, 'Cari berita'),
                    hintStyle: TextStyle(color: AppTheme.mutedText(context)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTheme.mutedText(context),
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: AppStrings.text(
                              context,
                              'Hapus pencarian',
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.close,
                              color: AppTheme.mutedText(context),
                            ),
                          ),
                    filled: true,
                    fillColor: AppTheme.surface(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: AppTheme.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Text(
                        category == 'All'
                            ? AppStrings.text(context, 'Semua')
                            : AppStrings.text(context, category),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.mutedText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: AppTheme.surface(context),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.border(context),
                      ),
                      shape: const StadiumBorder(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : _error != null
                    ? _buildMessage(
                        icon: Icons.cloud_off_outlined,
                        text: _error!,
                        action: TextButton.icon(
                          onPressed: _loadArticles,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppStrings.text(context, 'Coba Lagi')),
                        ),
                      )
                    : visibleArticles.isEmpty
                    ? _buildMessage(
                        icon: Icons.search_off,
                        text: AppStrings.text(
                          context,
                          'Tidak ada berita yang cocok.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadArticles,
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: visibleArticles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildArticleRow(visibleArticles[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String text,
    Widget? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: AppTheme.mutedText(context)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedText(context), fontSize: 13),
          ),
          ?action,
        ],
      ),
    ),
  );

  Widget _buildArticleRow(MarketNewsArticle article) => Material(
    color: AppTheme.surface(context),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: () => _openArticle(article),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                width: 104,
                height: 104,
                child: article.imageUrl == null
                    ? _imagePlaceholder(article.category)
                    : Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _imagePlaceholder(article.category),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category.isEmpty
                        ? article.source
                        : AppStrings.text(context, article.category),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${article.source}  •  ${_formatDate(article.publishedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedText(context),
                      fontSize: 10,
                    ),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.mutedText(context),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _imagePlaceholder(String category) => Container(
    color: AppTheme.surfaceRaised(context),
    alignment: Alignment.center,
    child: Icon(
      category.toLowerCase().contains('gold') ||
              category.toLowerCase().contains('emas')
          ? Icons.monetization_on_outlined
          : Icons.show_chart,
      color: Theme.of(context).colorScheme.primary,
    ),
  );

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const monthsId = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final months = _requestedLanguageCode == 'en' ? monthsEn : monthsId;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
