import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Models/historidata_model.dart';
import '../../Models/historikalkulator_model.dart';
import '../../Services/api_services.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/history_service.dart';
import '../../Services/market_news_service.dart';
import '../History/detail_histori.dart';
import 'market_news_detail.dart';
import 'market_news_list.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onViewAllHistory;
  final VoidCallback? onViewNotifications;
  final VoidCallback? onViewProfile;
  final bool historicalDataOnly;

  const HomeView({
    super.key,
    this.onViewAllHistory,
    this.onViewNotifications,
    this.onViewProfile,
    this.historicalDataOnly = false,
  });

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  // Tanggal Filter Default (MM/DD/YYYY)
  DateTime? _startDate = DateTime(2026, 7, 8); // 8 Juli 2026
  DateTime? _endDate = DateTime(2026, 8, 20); // 20 Agustus 2026

  List<GoldHistory> _rawHistoricalData = [];
  bool _isLoading = false;
  String? _loadError;
  int _currentPage = 1;
  final int _itemsPerPage = 8;
  String _selectedCategory = 'LGD';
  String _userName = 'Pengguna';
  String? _userPhotoPath;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  final PageController _newsPageController = PageController(
    viewportFraction: 0.94,
  );
  List<MarketNewsArticle> _latestNews = [];
  bool _isLoadingNews = true;
  String? _newsError;
  int _newsPage = 0;
  String? _newsLanguageCode;
  int _newsRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.historicalDataOnly) {
      _loadData();
    } else {
      _watchCurrentUser();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.historicalDataOnly) return;

    final languageCode = Localizations.localeOf(context).languageCode;
    if (_newsLanguageCode == languageCode) return;
    _newsLanguageCode = languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLatestNews(languageCode: languageCode);
    });
  }

  void _watchCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final emailName = currentUser.email?.split('@').first.trim();
    final fallbackName = currentUser.displayName?.trim().isNotEmpty == true
        ? currentUser.displayName!.trim()
        : (emailName?.isNotEmpty == true ? emailName! : 'Pengguna');

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final savedName = snapshot.data()?['nama']?.toString().trim();
          final savedPhotoPath =
              snapshot.data()?['foto_profil_path']?.toString() ??
              snapshot.data()?['photoUrl']?.toString();
          setState(() {
            _userName = savedName?.isNotEmpty == true
                ? savedName!
                : fallbackName;
            _userPhotoPath = savedPhotoPath;
          });
        });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _newsPageController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestNews({String? languageCode}) async {
    final requestGeneration = ++_newsRequestGeneration;
    if (mounted) {
      setState(() {
        _isLoadingNews = true;
        _newsError = null;
      });
    }

    try {
      final articles = await MarketNewsService.fetchLatest(
        languageCode: languageCode ?? _newsLanguageCode ?? 'id',
      );
      if (!mounted || requestGeneration != _newsRequestGeneration) return;
      setState(() {
        _latestNews = articles;
        _isLoadingNews = false;
        _newsPage = 0;
      });
      if (_newsPageController.hasClients) {
        _newsPageController.jumpToPage(0);
      }
    } on Exception catch (error) {
      if (!mounted || requestGeneration != _newsRequestGeneration) return;
      setState(() {
        _isLoadingNews = false;
        _newsError =
            '${AppStrings.text(context, 'Berita terbaru gagal dimuat.')} $error';
      });
    }
  }

  void _showCompanyInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.sizeOf(sheetContext).height * 0.9,
        decoration: BoxDecoration(
          color: AppTheme.background(sheetContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.border(sheetContext)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.text(sheetContext, 'PT. EQUITYWORLD FUTURES'),
                      style: TextStyle(
                        color: AppTheme.text(sheetContext),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.mutedText(sheetContext),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  _companyInfoParagraph(
                    sheetContext,
                    'PT Equityworld Futures ("EWF") hadir sebagai mitra investasi yang mengutamakan kepercayaan dan profesionalisme di industri perdagangan berjangka. Dengan fokus pada kualitas layanan dan edukasi berkelanjutan, EWF membantu nasabah menavigasi peluang pasar secara lebih terarah dan aman.',
                  ),
                  const SizedBox(height: 12),
                  _companyInfoParagraph(
                    sheetContext,
                    'Sejak mulai beroperasi pada tahun 2005, EWF terus tumbuh dan memperluas jangkauan layanan hingga memiliki tujuh kantor operasional di Jakarta, Surabaya, Semarang, Manado, dan Cirebon.',
                  ),
                  const SizedBox(height: 12),
                  _companyInfoParagraph(
                    sheetContext,
                    'Sebagai perusahaan pialang berjangka resmi, EWF terdaftar dan diawasi oleh Badan Pengawas Perdagangan Berjangka Komoditi (BAPPEBTI), Otoritas Jasa Keuangan (OJK), dan Bank Indonesia (BI), serta menjadi anggota PT Bursa Berjangka Jakarta (BBJ) dan PT Kliring Berjangka Indonesia (Persero). Dengan landasan regulasi yang kuat, EWF berkomitmen memberikan pengalaman transaksi yang transparan, akuntabel, dan berstandar tinggi.',
                  ),
                  _companyInfoHeading(sheetContext, 'Visi'),
                  _companyInfoParagraph(
                    sheetContext,
                    'Menjadi perusahaan pialang berjangka yang unggul dan terpercaya, dengan standar operasional yang modern, transparan, serta memberikan nilai strategis bagi perkembangan industri dan perekonomian nasional.',
                  ),
                  _companyInfoHeading(sheetContext, 'Misi'),
                  for (final mission in const [
                    'Menyediakan layanan perdagangan berjangka yang profesional, aman, dan berintegritas tinggi.',
                    'Mengembangkan kualitas sumber daya manusia untuk menghadirkan layanan yang kompeten dan berdaya saing.',
                    'Mengimplementasikan tata kelola perusahaan yang transparan dan akuntabel.',
                    'Memperluas akses edukasi serta literasi perdagangan berjangka kepada masyarakat.',
                    'Mengoptimalkan teknologi untuk mendukung operasional dan pengalaman nasabah secara efisien.',
                  ])
                    _companyInfoBullet(sheetContext, mission),
                  _companyInfoHeading(sheetContext, 'Nilai-Nilai Perusahaan'),
                  for (final value in const [
                    (
                      'Integritas Profesional',
                      'Menegakkan standar etika yang tinggi serta menjaga konsistensi tindakan dan keputusan dalam setiap aktivitas perusahaan.',
                    ),
                    (
                      'Fokus pada Nasabah',
                      'Mengutamakan kebutuhan dan tujuan investasi nasabah melalui layanan yang responsif, akurat, dan transparan.',
                    ),
                    (
                      'Disiplin Kepatuhan',
                      'Menjalankan seluruh proses bisnis sesuai kerangka regulasi dengan kontrol internal yang kuat dan berkelanjutan.',
                    ),
                    (
                      'Inovasi Berkelanjutan',
                      'Mendorong pengembangan teknologi, produk, dan proses kerja untuk menghadirkan pengalaman transaksi yang semakin efisien dan kompetitif.',
                    ),
                  ]) ...[
                    _companyInfoSubheading(sheetContext, value.$1),
                    _companyInfoParagraph(sheetContext, value.$2),
                  ],
                  _companyInfoHeading(sheetContext, 'Apa arti ORVIX?'),
                  _companyInfoParagraph(
                    sheetContext,
                    'OR terinspirasi dari kata or dalam bahasa Prancis yang berarti emas. VIX menggambarkan kesan teknologi, kecepatan, dan inovasi.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyInfoParagraph(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      AppStrings.text(context, text),
      style: TextStyle(
        color: AppTheme.mutedText(context),
        fontSize: 13,
        height: 1.55,
      ),
    ),
  );

  Widget _companyInfoHeading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Text(
      AppStrings.text(context, text),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _companyInfoSubheading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(
      AppStrings.text(context, text),
      style: TextStyle(
        color: AppTheme.text(context),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _companyInfoBullet(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7, right: 9),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(
          child: Text(
            AppStrings.text(context, text),
            style: TextStyle(
              color: AppTheme.mutedText(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCompanyInfoCard() => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: _showCompanyInfo,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.apartment_outlined,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.text(context, 'PT. EQUITYWORLD FUTURES'),
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.text(
                      context,
                      'Profil perusahaan, visi, misi, nilai, legalitas dan informasi ORVIX',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedText(context),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
              size: 25,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.text(context, 'Berita & Analisis Terbaru'),
                style: TextStyle(
                  color: AppTheme.text(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.text(context, 'Perbarui berita'),
              onPressed: _loadLatestNews,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            InkWell(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MarketNewsListScreen(),
                ),
              ),
              child: Text(
                AppStrings.text(context, 'Lihat Semua >'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingNews)
          SizedBox(
            height: 270,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else if (_newsError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: AppTheme.mutedText(context),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  _newsError!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.mutedText(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _loadLatestNews,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppStrings.text(context, 'Coba Lagi')),
                ),
              ],
            ),
          )
        else if (_latestNews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Text(
              AppStrings.text(context, 'Belum ada berita terbaru.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedText(context)),
            ),
          )
        else ...[
          SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _newsPageController,
              itemCount: _latestNews.length,
              onPageChanged: (page) => setState(() => _newsPage = page),
              itemBuilder: (context, index) =>
                  _buildNewsArticleCard(_latestNews[index]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _latestNews.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _newsPage == index ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _newsPage == index
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.border(context),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewsArticleCard(MarketNewsArticle article) => Container(
    margin: const EdgeInsets.only(right: 10, bottom: 2),
    decoration: BoxDecoration(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => MarketNewsDetailScreen(article: article),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: article.imageUrl == null
                  ? _newsImagePlaceholder(article.category)
                  : Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _newsImagePlaceholder(article.category),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category.isEmpty
                              ? article.source
                              : AppStrings.text(context, article.category),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${article.source}  •  ${_formatNewsDate(article.publishedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.mutedText(context),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.mutedText(context),
                        fontSize: 11,
                        height: 1.4,
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

  Widget _newsImagePlaceholder(String category) => Container(
    color: AppTheme.surfaceRaised(context),
    alignment: Alignment.center,
    child: Icon(
      category.toLowerCase().contains('gold') ||
              category.toLowerCase().contains('emas')
          ? Icons.monetization_on_outlined
          : Icons.show_chart,
      color: Theme.of(context).colorScheme.primary,
      size: 56,
    ),
  );

  String _formatNewsDate(DateTime? date) {
    if (date == null) return '';
    final english = Localizations.localeOf(context).languageCode == 'en';
    final months = english
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

  // 1. Ambil seluruh data dari slide 1 hingga slide terakhir
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await ApiService.getGoldHistory(
        maxPages: 10,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _rawHistoricalData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = AppStrings.text(
          context,
          'Data historical gagal dimuat. Periksa koneksi lalu coba lagi.',
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.text(context, 'Gagal memuat data: ')}$e',
            ),
          ),
        );
      }
    }
  }

  Future<void> refreshHistoricalData() => _loadData();

  // 2. Parser Teks Tanggal ("08 Jul 2026" / "12 Aug 2026" -> DateTime)
  DateTime? _parseDate(String dateStr) {
    try {
      String cleanStr = dateStr
          .replaceAll('\u00a0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final months = {
        'jan': 1,
        'januari': 1,
        'feb': 2,
        'februari': 2,
        'mar': 3,
        'maret': 3,
        'apr': 4,
        'april': 4,
        'may': 5,
        'mei': 5,
        'jun': 6,
        'juni': 6,
        'jul': 7,
        'juli': 7,
        'aug': 8,
        'agt': 8,
        'agu': 8,
        'agustus': 8,
        'sep': 9,
        'september': 9,
        'oct': 10,
        'okt': 10,
        'oktober': 10,
        'nov': 11,
        'november': 11,
        'dec': 12,
        'des': 12,
        'desember': 12,
      };

      final isoDate = RegExp(
        r'^(\d{4})-(\d{1,2})-(\d{1,2})',
      ).firstMatch(cleanStr);
      if (isoDate != null) {
        return DateTime(
          int.parse(isoDate.group(1)!),
          int.parse(isoDate.group(2)!),
          int.parse(isoDate.group(3)!),
        );
      }

      final slashDate = RegExp(
        r'^(\d{1,2})/(\d{1,2})/(\d{4})',
      ).firstMatch(cleanStr);
      if (slashDate != null) {
        return DateTime(
          int.parse(slashDate.group(3)!),
          int.parse(slashDate.group(1)!),
          int.parse(slashDate.group(2)!),
        );
      }

      final parts = cleanStr.split(' ');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = months[parts[1].toLowerCase()] ?? 1;
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  String _formatDisplayDate(String dateStr) {
    final date = _parseDate(dateStr);
    if (date == null) return dateStr;

    return '${date.day.toString().padLeft(2, '0')} ${AppStrings.monthName(date.month)} ${date.year}';
  }

  // 3. Filter Data Berdasarkan Rentang Tanggal yang Dipilih User
  List<GoldHistory> get _processedData {
    List<GoldHistory> list = List.from(_rawHistoricalData);

    if (_startDate != null && _endDate != null) {
      DateTime start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      DateTime end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );

      // Hanya simpan data di antara Start dan End
      list = list.where((item) {
        DateTime? dt = _parseDate(item.date);
        if (dt == null) return false;
        return !dt.isBefore(start) && !dt.isAfter(end);
      }).toList();
    }

    // Urutkan dari tanggal terlama ke terbaru (Ascending)
    list.sort((a, b) {
      DateTime? dtA = _parseDate(a.date);
      DateTime? dtB = _parseDate(b.date);
      if (dtA == null || dtB == null) return 0;
      return dtA.compareTo(dtB);
    });

    return list;
  }

  // 4. Paginasi Tampilan Aplikasi
  List<GoldHistory> get _paginatedData {
    final list = _processedData;
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= list.length) return [];
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > list.length) endIndex = list.length;
    return list.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final total = _processedData.length;
    if (total == 0) return 1;
    return (total / _itemsPerPage).ceil();
  }

  String? get _dateRangeNotice {
    if (_startDate == null || _endDate == null || _processedData.isEmpty) {
      return null;
    }

    final firstDate = _parseDate(_processedData.first.date);
    if (firstDate == null || !firstDate.isAfter(_startDate!)) return null;

    return 'Tidak ada data pada tanggal ${_formatDisplayDate('${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}')} sampai sebelum ${_formatDisplayDate(_processedData.first.date)}. Menampilkan data pertama yang tersedia.';
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && picked.isAfter(_endDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && picked.isBefore(_startDate!)) {
            _startDate = picked;
          }
        }
        _currentPage = 1; // Reset ke halaman 1 setiap ganti filter
      });
    }
  }

  Widget _buildHistoricalDataSection() {
    final maxPagesToShow = _totalPages > 4 ? 4 : _totalPages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFD36A28),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.text(context, 'Historical Data'),
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ApiService.supportedCategories.indexed.map((entry) {
            final index = entry.$1;
            final category = entry.$2;
            final selected = _selectedCategory == category;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == ApiService.supportedCategories.length - 1
                      ? 0
                      : 8,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (selected) return;
                    setState(() {
                      _selectedCategory = category;
                      _currentPage = 1;
                    });
                    _loadData();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFD36A28)
                          : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFD36A28)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppTheme.text(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              AppStrings.text(context, 'Mulai  '),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context),
              ),
            ),
            Expanded(child: _buildDateField(true)),
            const SizedBox(width: 10),
            Text(
              AppStrings.text(context, 'Sampai  '),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context),
              ),
            ),
            Expanded(child: _buildDateField(false)),
          ],
        ),
        if (_dateRangeNotice != null) ...[
          const SizedBox(height: 8),
          Text(
            _dateRangeNotice!,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A5A3B)),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Open', isHeader: true),
                    _buildTableCell('High', isHeader: true),
                    _buildTableCell('Low', isHeader: true),
                    _buildTableCell('Close', isHeader: true),
                  ],
                ),
              ),
              const Divider(),
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Color(0xFFD36A28),
                      ),
                    )
                  : _loadError != null
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadData,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : _paginatedData.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Tidak ada data pada rentang tanggal yang dipilih',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: _paginatedData.map((data) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  _buildTableCell(
                                    _formatDisplayDate(data.date),
                                  ),
                                  _buildTableCell(
                                    _formatDisplayNumber(data.open),
                                  ),
                                  _buildTableCell(
                                    _formatDisplayNumber(data.high),
                                  ),
                                  _buildTableCell(
                                    _formatDisplayNumber(data.low),
                                  ),
                                  _buildTableCell(
                                    _formatDisplayNumber(data.close),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.black.withValues(alpha: 0.14),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPageBtn('<<', onTap: () => _goToPage(1)),
            _buildPageBtn('<', onTap: () => _goToPage(_currentPage - 1)),
            for (int i = 1; i <= maxPagesToShow; i++)
              _buildPageBtn(
                '$i',
                isActive: _currentPage == i,
                onTap: () => _goToPage(i),
              ),
            _buildPageBtn('>', onTap: () => _goToPage(_currentPage + 1)),
            _buildPageBtn('>>', onTap: () => _goToPage(_totalPages)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicalDataOnly) {
      return SizedBox(
        width: double.infinity,
        child: _buildHistoricalDataSection(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 250,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? const [Color(0xFF253034), Color(0xFF0B1113)]
                        : const [Color(0xFFF2A674), Color(0xFFFFF8F3)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 16,
                20,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER (Logo ORVIX & Profil)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/orvix_logo.png',
                              width: 105,
                              fit: BoxFit.contain,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: Material(
                                    color: AppTheme.surface(context),
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: widget.onViewNotifications,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.border(context),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.notifications_none,
                                          color: AppTheme.text(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: Material(
                                    color: AppTheme.surface(context),
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/kepompong-logo.png',
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: Material(
                                    color: AppTheme.surfaceRaised(context),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: widget.onViewProfile,
                                      child: _buildProfilePhoto(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: AppStrings.text(context, 'Halo, '),
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.normal,
                            ),
                            children: [
                              TextSpan(
                                text: '$_userName!',
                                style: TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.text(
                            context,
                            'Siap melakukan perhitungan hari ini?',
                          ),
                          style: TextStyle(
                            fontFamily: 'sans-serif-medium',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BANNER
                  Container(
                    width: double.infinity,
                    height: 146,
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).brightness == Brightness.dark
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF263235), Color(0xFF192326)],
                            )
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFFFF0D9), Color(0xFFE9B18F)],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.border(context),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 55,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: AppStrings.text(
                                    context,
                                    'Hitung dengan ',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'sans-serif',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text(context),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.text(context, 'Cepat '),
                                      style: TextStyle(
                                        fontFamily: 'sans-serif',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppStrings.text(context, 'dan '),
                                    ),
                                    TextSpan(
                                      text: AppStrings.text(context, 'Akurat'),
                                      style: TextStyle(
                                        fontFamily: 'sans-serif',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.text(
                                  context,
                                  'ORVIX membantu perhitungan Emas Fisik, Pivot Point, dan NEST lebih mudah',
                                ),
                                style: TextStyle(
                                  fontFamily: 'sans-serif-medium',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.mutedText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 45,
                          child: Image.asset(
                            'assets/home_page.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildCompanyInfoCard(),
                  const SizedBox(height: 22),
                  _buildNewsSection(),
                  const SizedBox(height: 24),

                  // PERHITUNGAN TERAKHIR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD36A28),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.text(context, 'Perhitungan Terakhir'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text(context),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onViewAllHistory,
                        child: Text(
                          AppStrings.text(context, 'Lihat Semua >'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<HistoryModel>>(
                    stream: HistoryService.watchHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final recent = (snapshot.data ?? []).take(4).toList();
                      if (recent.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              AppStrings.text(
                                context,
                                'Belum ada perhitungan.',
                              ),
                              style: TextStyle(
                                color: AppTheme.mutedText(context),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: recent.map(_buildRecentHistoryCard).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final photoPath = _userPhotoPath;
    if (photoPath != null && photoPath.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          photoPath,
          width: 45,
          height: 45,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, color: Color(0xFFD36A28)),
        ),
      );
    }

    return const Icon(Icons.person, color: Color(0xFFD36A28));
  }

  // WIDGET HELPER
  Widget _buildTableCell(String value, {bool isHeader = false}) {
    return Expanded(
      child: Center(
        child: Text(
          AppStrings.text(context, value),
          textAlign: TextAlign.center,
          style: isHeader
              ? TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text(context),
                )
              : TextStyle(
                  fontFamily: 'sans-serif-medium',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text(context),
                ),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isStart) {
    DateTime? date = isStart ? _startDate : _endDate;
    String text = date == null
        ? 'mm/dd/yyyy'
        : '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: date == null
                    ? AppTheme.mutedText(context)
                    : AppTheme.text(context),
              ),
            ),
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDisplayNumber(double value) {
    final formatter = NumberFormat('#,##0.##', 'en_US');
    return formatter.format(value);
  }

  Widget _buildRecentHistoryCard(HistoryModel history) {
    final date = history.createdAt;
    final dateText =
        '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailHistoryScreen(history: history),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.jenisKalkulator,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.text(context, 'Hasil: ')}${history.hasil.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.text(context),
                    ),
                  ),
                ],
              ),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageBtn(
    String label, {
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD36A28) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.white : AppTheme.text(context),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) => AppStrings.monthName(month);
}
