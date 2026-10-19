import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/market_news_service.dart';

class MarketNewsDetailScreen extends StatefulWidget {
  final MarketNewsArticle article;

  const MarketNewsDetailScreen({super.key, required this.article});

  @override
  State<MarketNewsDetailScreen> createState() => _MarketNewsDetailScreenState();
}

class _MarketNewsDetailScreenState extends State<MarketNewsDetailScreen> {
  late Future<MarketNewsArticle> _articleFuture;
  String? _requestedLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_requestedLanguageCode == languageCode) return;
    _requestedLanguageCode = languageCode;
    _loadArticle(languageCode);
  }

  void _loadArticle(String languageCode) {
    _articleFuture = MarketNewsService.fetchArticleDetails(
      widget.article,
      languageCode: languageCode,
    );
  }

  Future<void> _openSource() async {
    try {
      final opened = await launchUrl(
        widget.article.articleUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showOpenError();
      }
    } on Exception {
      if (mounted) _showOpenError();
    }
  }

  void _showOpenError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.text(context, 'Tautan tidak dapat dibuka.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = AppTheme.background(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: pageBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: pageBackground,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: FutureBuilder<MarketNewsArticle>(
            future: _articleFuture,
            builder: (context, snapshot) {
              final article = snapshot.data ?? widget.article;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHero(context, article)),
                  SliverToBoxAdapter(
                    child: _buildArticleBody(context, article, snapshot),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, MarketNewsArticle article) {
    return SizedBox(
      height: 390 + MediaQuery.paddingOf(context).top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (article.imageUrl != null)
            Image.network(
              article.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _heroImagePlaceholder(context),
            )
          else
            _heroImagePlaceholder(context),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.64),
                  AppTheme.background(context),
                ],
                stops: const [0, 0.28, 0.72, 1],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 14,
            child: _heroAction(
              icon: Icons.arrow_back,
              tooltip: AppStrings.text(context, 'Kembali'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 14,
            child: _heroAction(
              icon: Icons.open_in_new,
              tooltip: AppStrings.text(context, 'Buka sumber berita'),
              onPressed: _openSource,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article.category.isEmpty
                        ? article.source
                        : AppStrings.text(context, article.category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${article.source}  •  ${_formatDate(context, article.publishedAt)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => Material(
    color: Colors.black.withValues(alpha: 0.38),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
    ),
  );

  Widget _heroImagePlaceholder(BuildContext context) => Container(
    color: AppTheme.surfaceRaised(context),
    alignment: Alignment.center,
    child: Icon(
      Icons.newspaper_outlined,
      color: Theme.of(context).colorScheme.primary,
      size: 68,
    ),
  );

  Widget _buildArticleBody(
    BuildContext context,
    MarketNewsArticle originalArticle,
    AsyncSnapshot<MarketNewsArticle> snapshot,
  ) {
    final article = snapshot.data ?? originalArticle;
    final paragraphs = article.contentParagraphs;
    final hasContent = paragraphs.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.source,
                        style: TextStyle(
                          color: AppTheme.text(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppStrings.text(context, 'Sumber berita'),
                        style: TextStyle(
                          color: AppTheme.mutedText(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !hasContent)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else if (snapshot.hasError && !hasContent) ...[
              Text(
                article.summary.isNotEmpty
                    ? article.summary
                    : AppStrings.text(
                        context,
                        'Konten lengkap belum dapat dimuat.',
                      ),
                style: TextStyle(
                  color: AppTheme.text(context),
                  fontSize: 15,
                  height: 1.65,
                ),
              ),
              if (Localizations.localeOf(context).languageCode == 'en' &&
                  widget.article.contentParagraphs.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final paragraph in widget.article.contentParagraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      paragraph,
                      style: TextStyle(
                        color: AppTheme.text(context),
                        fontSize: 15,
                        height: 1.65,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                AppStrings.text(
                  context,
                  'Anda masih dapat membuka artikel asli dari sumber berita.',
                ),
                style: TextStyle(
                  color: AppTheme.mutedText(context),
                  fontSize: 12,
                ),
              ),
            ] else if (hasContent)
              for (final paragraph in paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    paragraph,
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                )
            else
              Text(
                article.summary.isNotEmpty
                    ? article.summary
                    : AppStrings.text(
                        context,
                        'Konten lengkap belum tersedia dari sumber berita.',
                      ),
                style: TextStyle(
                  color: AppTheme.text(context),
                  fontSize: 15,
                  height: 1.65,
                ),
              ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.border(context)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openSource,
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  AppStrings.text(context, 'Buka artikel di situs sumber'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: AppTheme.border(context)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final languageCode = Localizations.localeOf(context).languageCode;
    final months = languageCode == 'en'
        ? const [
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
          ]
        : const [
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
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year} • $hour:$minute';
  }
}
