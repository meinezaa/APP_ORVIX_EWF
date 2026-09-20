import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../Models/historikalkulator_model.dart';
import 'kelola_staff.dart';
import 'laporan.dart';
import '../Home/beranda_admin.dart';
import '../Profil/profil_admin.dart';

class AnalisisPerhitunganView extends StatefulWidget {
  const AnalisisPerhitunganView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AnalisisPerhitunganView> createState() =>
      _AnalisisPerhitunganViewState();
}

class CalculationTypeSummary {
  final int total;
  final int physical;
  final int pivot;
  final int nest;

  const CalculationTypeSummary({
    required this.total,
    required this.physical,
    required this.pivot,
    required this.nest,
  });
}

CalculationTypeSummary summarizeCalculationTypes(List<HistoryModel> history) {
  int physical = 0;
  int pivot = 0;
  int nest = 0;

  for (final item in history) {
    final type = item.jenisKalkulator.toLowerCase();
    if (type.contains('nest')) {
      nest++;
    } else if (type.contains('pivot')) {
      pivot++;
    } else if (type.contains('emas') || type.contains('fisik')) {
      physical++;
    }
  }

  return CalculationTypeSummary(
    total: history.length,
    physical: physical,
    pivot: pivot,
    nest: nest,
  );
}

class _AnalisisPerhitunganViewState extends State<AnalisisPerhitunganView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream;
  Timer? _searchDebounce;
  DateTimeRange? _selectedRange;
  String _searchText = '';
  bool _isSearching = false;
  bool _showStaff = false;
  bool _showReport = false;
  List<HistoryModel> _cachedHistory = const [];

  static const _orange = Color(0xFFF26422);
  static const _blue = Color(0xFF4385F4);
  static const _green = Color(0xFF22C55E);
  static const _pageBackground = Color(0xFFFFF9F4);

  @override
  void initState() {
    super.initState();
    _historyStream = FirebaseFirestore.instance
        .collectionGroup('calculation_history')
        .snapshots();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _selectedRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _orange, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) setState(() => _selectedRange = range);
  }

  List<HistoryModel> _sortHistory(List<HistoryModel> history) {
    final sorted = List<HistoryModel>.from(history);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<HistoryModel> _filterHistory(List<HistoryModel> history) {
    final query = _searchText.trim().toLowerCase();
    return _sortHistory(
      history.where((item) {
        final inRange =
            _selectedRange == null ||
            (!item.createdAt.isBefore(_selectedRange!.start) &&
                !item.createdAt.isAfter(
                  _selectedRange!.end.add(const Duration(days: 1)),
                ));
        final matchesSearch =
            query.isEmpty ||
            item.userName.toLowerCase().contains(query) ||
            (item.email ?? '').toLowerCase().contains(query);
        return inRange && matchesSearch;
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _showReport
        ? _buildReportContent()
        : _showStaff
        ? _buildStaffContent()
        : _buildAnalysisStream();
    if (widget.embedded) return content;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(top: false, child: content),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.bar_chart_rounded, 'Analitik'),
            _buildNavItem(2, Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == 1;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        final page = index == 0
            ? const DashboardScreen()
            : const AdminProfileScreen();
        Navigator.of(context).pushReplacement(_smoothRoute(page));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? _orange : Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  PageRoute<void> _smoothRoute(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAnalysisStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat analisis: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_cachedHistory.isNotEmpty) return _buildContent(_cachedHistory);
          return const Center(child: CircularProgressIndicator(color: _orange));
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            final profiles = <String, Map<String, dynamic>>{
              for (final doc in usersSnapshot.data?.docs ?? const [])
                doc.id: doc.data(),
            };
            final profilesByEmail = <String, Map<String, dynamic>>{
              for (final profile in profiles.values)
                if (_profileValue(profile, ['email', 'user_email'], null) !=
                    null)
                  _profileValue(profile, [
                    'email',
                    'user_email',
                  ], null)!.toLowerCase(): profile,
            };
            final normalized = (snapshot.data?.docs ?? const []).map((doc) {
              final item = HistoryModel.fromFirestore(doc);
              final uid = item.userId.isNotEmpty
                  ? item.userId
                  : doc.reference.parent.parent?.id ?? '';
              final profile =
                  profiles[uid] ??
                  profilesByEmail[item.email?.trim().toLowerCase()];
              if (profile == null) return item;
              return item.copyWith(
                userId: uid,
                userName:
                    _profileValue(profile, ['nama', 'name'], item.userName) ??
                    item.userName,
                email: _profileValue(profile, [
                  'email',
                  'user_email',
                ], item.email),
              );
            }).toList();
            final history = _filterHistory(normalized);
            _cachedHistory = history;
            return _buildContent(history);
          },
        );
      },
    );
  }

  String? _profileValue(
    Map<String, dynamic> data,
    List<String> keys,
    String? fallback,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  Widget _buildStaffContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        _buildHeader(showStaff: true),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: KelolaStaffContent(),
        ),
      ],
    );
  }

  Widget _buildReportContent() {
    return Column(
      children: [
        _buildHeader(showReport: true),
        const Expanded(child: LaporanView(embedded: true)),
      ],
    );
  }

  Widget _buildContent(List<HistoryModel> history) {
    final summary = summarizeCalculationTypes(history);
    final total = summary.total;
    final physical = summary.physical;
    final pivot = summary.pivot;
    final nest = summary.nest;
    final physicalRate = total == 0 ? 0.0 : physical / total * 100;
    final pivotRate = total == 0 ? 0.0 : pivot / total * 100;
    final nestRate = total == 0 ? 0.0 : nest / total * 100;
    return RefreshIndicator(
      color: _orange,
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 12),
                _buildSummaryCards(
                  total,
                  physical,
                  pivot,
                  nest,
                  physicalRate,
                  pivotRate,
                  nestRate,
                ),
                const SizedBox(height: 16),
                _buildTrendCard(history),
                const SizedBox(height: 16),
                _buildBreakdownCard(
                  physical,
                  pivot,
                  nest,
                  total,
                  physicalRate,
                  pivotRate,
                  nestRate,
                ),
                const SizedBox(height: 16),
                _buildPerformanceCard(history),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({bool showStaff = false, bool showReport = false}) {
    return SizedBox(
      height: 182,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 38),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD0A5), Color(0xFFFFA05B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 4),
                Center(
                  child: Image.asset(
                    'assets/orvix_logo.png',
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 34,
                  child: SingleChildScrollView(
                    controller: _tabScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _adminMenu(
                          'Analisis Perhitungan',
                          !showStaff && !showReport,
                          Icons.analytics_outlined,
                          onTap: (!showStaff && !showReport)
                              ? null
                              : () => setState(() {
                                  _showStaff = false;
                                  _showReport = false;
                                }),
                        ),
                        _adminMenu(
                          'Kelola Staff',
                          showStaff,
                          Icons.groups_outlined,
                          onTap: showStaff
                              ? null
                              : () => setState(() {
                                  _showStaff = true;
                                  _showReport = false;
                                }),
                        ),
                        _adminMenu(
                          'Laporan',
                          showReport,
                          Icons.description_outlined,
                          onTap: showReport
                              ? null
                              : () => setState(() {
                                  _showReport = true;
                                  _showStaff = false;
                                }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -24,
            child: Container(
              height: 48,
              decoration: const BoxDecoration(
                color: _pageBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminMenu(
    String label,
    bool selected,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE75E14)
              : Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : const Color(0xFF8D7265),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: selected ? Colors.white : const Color(0xFF8D7265),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final rangeText = _selectedRange == null
        ? 'Pilih tanggal'
        : '${DateFormat('dd MMM yyyy').format(_selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)}';
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama staff...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _orange,
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: _orange,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(rangeText, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchText = '';
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchText = value;
        _isSearching = false;
      });
    });
  }

  Widget _buildSummaryCards(
    int total,
    int physical,
    int pivot,
    int nest,
    double physicalRate,
    double pivotRate,
    double nestRate,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.38,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
          'Total Perhitungan',
          '$total',
          'Semua jenis',
          _orange,
          Icons.calculate_outlined,
        ),
        _summaryCard(
          'Emas Fisik',
          '$physical',
          '${physicalRate.toStringAsFixed(1)}% dari total',
          const Color(0xFFF39A17),
          Icons.show_chart_rounded,
        ),
        _summaryCard(
          'Pivot Point',
          '$pivot',
          '${pivotRate.toStringAsFixed(1)}% dari total',
          _blue,
          Icons.bar_chart_rounded,
        ),
        _summaryCard(
          'NEST',
          '$nest',
          '${nestRate.toStringAsFixed(1)}% dari total',
          _green,
          Icons.insights_rounded,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    String caption,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 27,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 10, color: Color(0xFF4DAE82)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(List<HistoryModel> history) {
    final values = _dailyValues(history);
    return _panel(
      title: 'Tren Perhitungan',
      trailing: '7 hari terakhir',
      child: Column(
        children: [
          const Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _Legend(color: _orange, label: 'Emas Fisik'),
              _Legend(color: _blue, label: 'Pivot Point'),
              _Legend(color: _green, label: 'NEST'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 210,
            child: CustomPaint(painter: _LineChartPainter(values)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    int physical,
    int pivot,
    int nest,
    int total,
    double physicalRate,
    double pivotRate,
    double nestRate,
  ) {
    return _panel(
      title: 'Perbandingan Jenis Perhitungan',
      trailing: 'Total $total',
      child: Row(
        children: [
          SizedBox(
            width: 145,
            height: 145,
            child: CustomPaint(
              painter: _DonutChartPainter(physical, pivot, nest),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _breakdownRow(_orange, 'Emas Fisik', physical, physicalRate),
                const SizedBox(height: 18),
                _breakdownRow(_blue, 'Pivot Point', pivot, pivotRate),
                const SizedBox(height: 18),
                _breakdownRow(_green, 'NEST', nest, nestRate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(Color color, String label, int value, double rate) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 11),
        const SizedBox(width: 7),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(
          '$value · ${rate.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(List<HistoryModel> history) {
    final staffCounts = <String, int>{};
    final staffNames = <String, String>{};
    for (final item in history) {
      if (item.role.toLowerCase() == 'admin') continue;
      final name = item.userName.trim();
      if (name.isEmpty) continue;
      final identity = item.userId.trim().isNotEmpty
          ? item.userId.trim()
          : (item.email ?? '').trim().toLowerCase().isNotEmpty
          ? item.email!.trim().toLowerCase()
          : name.toLowerCase();
      staffNames.putIfAbsent(identity, () => name);
      staffCounts[identity] = (staffCounts[identity] ?? 0) + 1;
    }
    final sortedStaff =
        staffCounts.entries
            .map(
              (entry) =>
                  MapEntry(staffNames[entry.key] ?? entry.key, entry.value),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedStaff.isEmpty ? 1 : sortedStaff.first.value;
    final namedHistoryCount = history
        .where(
          (item) =>
              item.role.toLowerCase() != 'admin' &&
              item.userName.trim().isNotEmpty,
        )
        .length;
    return _panel(
      title: 'Performa Staff',
      trailing: 'Periode terpilih',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sortedStaff.isEmpty)
            const Text(
              'Belum ada data staff pada periode ini',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...sortedStaff.take(5).map((entry) {
              final percentage = namedHistoryCount == 0
                  ? 0.0
                  : entry.value / namedHistoryCount * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} · ${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: entry.value / maxValue,
                        minHeight: 7,
                        color: _orange,
                        backgroundColor: const Color(0xFFFFE7DA),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  bool _isPhysical(HistoryModel item) {
    final type = item.jenisKalkulator.toLowerCase();
    return type.contains('emas') || type.contains('fisik');
  }

  List<List<double>> _dailyValues(List<HistoryModel> history) {
    final now = DateTime.now();
    final physical = List<double>.filled(7, 0);
    final pivot = List<double>.filled(7, 0);
    final nest = List<double>.filled(7, 0);

    for (final item in history) {
      final daysAgo = DateTime(now.year, now.month, now.day)
          .difference(
            DateTime(
              item.createdAt.year,
              item.createdAt.month,
              item.createdAt.day,
            ),
          )
          .inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final index = 6 - daysAgo;
        if (_isNest(item)) {
          nest[index]++;
        } else if (_isPivot(item)) {
          pivot[index]++;
        } else if (_isPhysical(item)) {
          physical[index]++;
        }
      }
    }
    return [physical, pivot, nest];
  }

  bool _isNest(HistoryModel item) {
    final type = item.jenisKalkulator.toLowerCase();
    return type.contains('nest');
  }

  bool _isPivot(HistoryModel item) {
    final type = item.jenisKalkulator.toLowerCase();
    return type.contains('pivot');
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    ],
  );
}

class _LineChartPainter extends CustomPainter {
  final List<List<double>> series;
  const _LineChartPainter(this.series);

  @override
  void paint(Canvas canvas, Size size) {
    final highestValue = series
        .expand((line) => line)
        .fold<double>(1, (value, item) => item > value ? item : value);
    final max = (highestValue / 5).ceil() * 5.0;
    final grid = Paint()
      ..color = const Color(0xFFEEDDD3)
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = const Color(0xFF9B8274)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(28, y), Offset(size.width, y), grid);
      final label = TextPainter(
        text: TextSpan(
          text: '${(max / 4 * (4 - i)).round()}',
          style: const TextStyle(fontSize: 9, color: Colors.black45),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - 6));
    }
    canvas.drawLine(const Offset(28, 0), Offset(28, size.height), axis);
    canvas.drawLine(
      Offset(28, size.height),
      Offset(size.width, size.height),
      axis,
    );
    final colors = [
      _AnalisisPerhitunganViewState._orange,
      _AnalisisPerhitunganViewState._blue,
      _AnalisisPerhitunganViewState._green,
    ];
    for (var lineIndex = 0; lineIndex < series.length; lineIndex++) {
      final points = <Offset>[];
      for (var i = 0; i < series[lineIndex].length; i++) {
        final x = 28 + i * (size.width - 28) / 6;
        final y =
            size.height - (series[lineIndex][i] / max * (size.height - 12)) - 6;
        points.add(Offset(x, y));
      }
      final paint = Paint()
        ..color = colors[lineIndex]
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
      final dotPaint = Paint()..color = colors[lineIndex];
      for (final point in points) {
        canvas.drawCircle(point, 3, dotPaint);
      }
    }
    const labels = ['-6h', '-5h', '-4h', '-3h', '-2h', '-1h', 'Hari ini'];
    for (var i = 0; i < labels.length; i++) {
      final label = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 8, color: Colors.black45),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final x = 28 + i * (size.width - 28) / 6 - label.width / 2;
      label.paint(canvas, Offset(x, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series;
}

class _DonutChartPainter extends CustomPainter {
  final int first;
  final int second;
  final int third;
  const _DonutChartPainter(this.first, this.second, [this.third = 0]);

  @override
  void paint(Canvas canvas, Size size) {
    final total = first + second + third;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 9;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = const Color(0xFFEAF0FA);
    canvas.drawCircle(center, radius, base);
    if (total > 0) {
      var start = -1.5708;
      final segments = [
        MapEntry(first, _AnalisisPerhitunganViewState._orange),
        MapEntry(second, _AnalisisPerhitunganViewState._blue),
        MapEntry(third, _AnalisisPerhitunganViewState._green),
      ];
      for (final segment in segments) {
        final value = segment.key;
        if (value <= 0) continue;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = 24
          ..color = segment.value;
        final sweep = value / total * 6.2832;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          paint,
        );
        start += sweep;
      }
    }
    final text = TextPainter(
      text: TextSpan(
        text: '$total',
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Color(0xFF362D29),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.first != first ||
      oldDelegate.second != second ||
      oldDelegate.third != third;
}
