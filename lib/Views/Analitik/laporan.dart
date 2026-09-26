import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../Models/historikalkulator_model.dart';

class LaporanView extends StatefulWidget {
  const LaporanView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  static const _orange = Color(0xFFE75E14);
  static const _blue = Color(0xFF5757E8);
  static const _green = Color(0xFF0A9B70);
  static const _background = Color(0xFFFFF9F4);

  final _historyStream = FirebaseFirestore.instance
      .collectionGroup('calculation_history')
      .snapshots();
  DateTimeRange _range = _currentMonth();
  String _period = 'Bulan Ini';
  String _type = 'Semua Jenis';
  String _staff = 'Semua Staff';

  static DateTimeRange _currentMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat laporan: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                if (_profileValue(profile, [
                      'email',
                      'user_email',
                      'email_address',
                    ], null) !=
                    null)
                  _profileValue(profile, [
                    'email',
                    'user_email',
                    'email_address',
                  ], null)!.toLowerCase(): profile,
            };
            final allHistory = (snapshot.data?.docs ?? const []).map((doc) {
              final history = HistoryModel.fromFirestore(doc);
              final uid = history.userId.isNotEmpty
                  ? history.userId
                  : doc.reference.parent.parent?.id ?? '';
              final profile =
                  profiles[uid] ??
                  profilesByEmail[history.email?.trim().toLowerCase()];
              if (profile == null) return history;
              return history.copyWith(
                userId: uid,
                userName: _profileValue(profile, [
                  'nama',
                  'name',
                ], history.userName),
                email: _profileValue(profile, [
                  'email',
                  'user_email',
                  'email_address',
                ], history.email),
              );
            }).toList();
            final filtered = _filter(allHistory);
            return _buildPage(allHistory, filtered);
          },
        );
      },
    );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(top: false, child: content),
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

  bool _isHiddenStaffName(String name) => name.trim().toLowerCase() == 'staff';

  List<HistoryModel> _filter(List<HistoryModel> history) {
    return history.where((item) {
      final inRange =
          !item.createdAt.isBefore(_range.start) &&
          item.createdAt.isBefore(_range.end.add(const Duration(days: 1)));
      final type = item.jenisKalkulator.toLowerCase();
      final matchesType =
          _type == 'Semua Jenis' ||
          (_type == 'Emas Fisik' &&
              (type.contains('emas') || type.contains('fisik'))) ||
          (_type == 'Pivot Point' && type.contains('pivot')) ||
          (_type == 'NEST' && type.contains('nest'));
      final matchesStaff = _staff == 'Semua Staff' || item.userName == _staff;
      return inRange && matchesType && matchesStaff;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Widget _buildPage(List<HistoryModel> allHistory, List<HistoryModel> history) {
    final physical = history.where(_isPhysical).length;
    final pivot = history.where(_isPivot).length;
    final nest = history.where(_isNest).length;
    final total = history.length;
    final staffNames =
        allHistory
            .map((item) => item.userName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return RefreshIndicator(
      color: _orange,
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          if (!widget.embedded) _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterPanel(staffNames),
                const SizedBox(height: 14),
                _sectionLabel('RINGKASAN METRIK', 'Total: $total Sesi'),
                const SizedBox(height: 8),
                _buildMetricGrid(total, physical, pivot, nest),
                const SizedBox(height: 14),
                _buildComparisonCard(total, physical, pivot, nest),
                const SizedBox(height: 14),
                _buildStaffCard(history),
                const SizedBox(height: 14),
                _buildReportFooter(history),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 158,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC58D), Color(0xFFFF873D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/orvix_logo.png', height: 30),
              const Spacer(),
              const Text(
                'Laporan Analitik',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _topTab(
                'Analisis',
                false,
                Icons.analytics_outlined,
                () => Navigator.pop(context),
              ),
              _topTab(
                'Kelola Staff',
                false,
                Icons.groups_outlined,
                () => Navigator.pop(context),
              ),
              _topTab('Laporan', true, Icons.description_outlined, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topTab(
    String label,
    bool selected,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _orange : Colors.white.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.brown.shade400,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Colors.white : Colors.brown.shade400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(List<String> staffNames) {
    final rangeText =
        '${DateFormat('dd MMM yyyy').format(_range.start)} - ${DateFormat('dd MMM yyyy').format(_range.end)}';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 16, color: _orange),
              const SizedBox(width: 7),
              const Text(
                'PARAMETER LAPORAN',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _liveBadge(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              'Hari Ini',
              '7 Hari',
              'Bulan Ini',
            ].map((item) => Expanded(child: _periodButton(item))).toList(),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD9C2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: _orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rentang: $rangeText',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Text(
                    'Ubah',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown('Jenis', _type, [
                  'Semua Jenis',
                  'Emas Fisik',
                  'Pivot Point',
                  'NEST',
                ], (value) => setState(() => _type = value)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown('Staff', _staff, [
                  'Semua Staff',
                  ...staffNames,
                ], (value) => setState(() => _staff = value)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8DE2C2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: _green),
          SizedBox(width: 5),
          Text(
            'Data Terkini',
            style: TextStyle(
              fontSize: 10,
              color: _green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodButton(String label) {
    final selected = _period == label;
    return GestureDetector(
      onTap: () => _setPeriod(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _orange : const Color(0xFFF7F1ED),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE3DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text('$label: $item', overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }

  Future<void> _selectRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _orange, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _range = range;
        _period = 'Bulan Ini';
      });
    }
  }

  void _setPeriod(String label) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day);
    if (label == 'Hari Ini') {
      start = DateTime(now.year, now.month, now.day);
    } else if (label == '7 Hari') {
      start = end.subtract(const Duration(days: 6));
    } else {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    }
    setState(() {
      _period = label;
      _range = DateTimeRange(start: start, end: end);
    });
  }

  Widget _sectionLabel(String title, String trailing) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      ),
    ],
  );

  Widget _buildMetricGrid(int total, int physical, int pivot, int nest) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _metric('Total Hitung', total, _blue, Icons.bar_chart_rounded),
        _metric(
          'Emas Fisik',
          physical,
          _orange,
          Icons.monetization_on_outlined,
        ),
        _metric('Pivot Point', pivot, _blue, Icons.trending_up_rounded),
        _metric('NEST', nest, _green, Icons.insights_outlined),
      ],
    );
  }

  Widget _metric(String label, int value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: .12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value == 0 ? 'Belum ada data' : 'Data terfilter',
              style: const TextStyle(
                fontSize: 10,
                color: _green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _buildComparisonCard(int total, int physical, int pivot, int nest) {
    final max = [physical, pivot, nest].fold<int>(1, (a, b) => a > b ? a : b);
    return _panel(
      title: 'Perbandingan Jenis Perhitungan',
      subtitle: 'Proporsi hasil kalkulasi pada periode aktif',
      child: Column(
        children: [
          _bar('Emas Fisik', physical, max, _orange),
          _bar('Pivot Point', pivot, max, _blue),
          _bar('NEST', nest, max, _green),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _donut(total, physical, pivot, nest)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend('Emas Fisik', physical, total, _orange),
                    _legend('Pivot Point', pivot, total, _blue),
                    _legend('NEST', nest, total, _green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, int value, int max, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(fontSize: 10)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / max,
              minHeight: 9,
              backgroundColor: color.withValues(alpha: .1),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 27,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _donut(int total, int physical, int pivot, int nest) => SizedBox(
    height: 116,
    width: 116,
    child: CustomPaint(
      painter: _DonutPainter(physical: physical, pivot: pivot, nest: nest),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(fontSize: 9, color: Colors.black54),
            ),
            Text(
              '$total',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const Text(
              '100%',
              style: TextStyle(
                fontSize: 9,
                color: _orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _legend(String label, int value, int total, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 10))),
        Text(
          '${total == 0 ? 0 : (value / total * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _buildStaffCard(List<HistoryModel> history) {
    final grouped = <String, List<HistoryModel>>{};
    final names = <String, String>{};
    for (final item in history) {
      final name = item.userName.trim().isEmpty
          ? 'Staff'
          : item.userName.trim();
      final identity = item.userId.trim().isNotEmpty
          ? item.userId.trim()
          : (item.email ?? '').trim().toLowerCase().isNotEmpty
          ? item.email!.trim().toLowerCase()
          : name.toLowerCase();
      names.putIfAbsent(identity, () => name);
      grouped.putIfAbsent(identity, () => []).add(item);
    }
    final rows =
        grouped.entries
            .map(
              (entry) => MapEntry(names[entry.key] ?? entry.key, entry.value),
            )
            .where((entry) => !_isHiddenStaffName(entry.key))
            .toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return _panel(
      title: 'Performa Staff Analisis',
      subtitle: 'Kontribusi perhitungan periode aktif',
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                '${rows.length} Personil',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada data pada periode ini.'),
            )
          else
            ...rows.take(6).toList().asMap().entries.map((entry) {
              final row = entry.value;
              final percent = history.isEmpty
                  ? 0.0
                  : row.value.length / history.length * 100;
              return _staffRow(
                entry.key + 1,
                row.key,
                row.value.length,
                percent,
              );
            }),
        ],
      ),
    );
  }

  Widget _staffRow(int rank, String name, int count, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: rank == 1
                ? const Color(0xFFFFEEE2)
                : const Color(0xFFF1F1F1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: rank == 1 ? _orange : Colors.black54,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count perhitungan',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: _orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildReportFooter(List<HistoryModel> history) {
    return Column(
      children: [
        const Text(
          'Dokumen laporan dibuat otomatis oleh Sistem Analitik ORVIX',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        Text(
          'Waktu cetak: ${DateFormat('dd MMM yyyy • HH:mm').format(DateTime.now())}',
          style: const TextStyle(fontSize: 9, color: Colors.black38),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _downloadPdf(history),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Unduh Laporan (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isPhysical(HistoryModel item) =>
      item.jenisKalkulator.toLowerCase().contains('emas') ||
      item.jenisKalkulator.toLowerCase().contains('fisik');
  bool _isPivot(HistoryModel item) =>
      item.jenisKalkulator.toLowerCase().contains('pivot');
  bool _isNest(HistoryModel item) =>
      item.jenisKalkulator.toLowerCase().contains('nest');

  Future<void> _downloadPdf(List<HistoryModel> history) async {
    final document = pw.Document();
    final physical = history.where(_isPhysical).length;
    final pivot = history.where(_isPivot).length;
    final nest = history.where(_isNest).length;
    final grouped = <String, int>{};
    final names = <String, String>{};
    for (final item in history) {
      final name = item.userName.trim().isEmpty
          ? 'Staff'
          : item.userName.trim();
      final identity = item.userId.trim().isNotEmpty
          ? item.userId.trim()
          : (item.email ?? '').trim().toLowerCase().isNotEmpty
          ? item.email!.trim().toLowerCase()
          : name.toLowerCase();
      names.putIfAbsent(identity, () => name);
      grouped[identity] = (grouped[identity] ?? 0) + 1;
    }
    final staffRows =
        grouped.entries
            .map(
              (entry) => MapEntry(names[entry.key] ?? entry.key, entry.value),
            )
            .where((entry) => !_isHiddenStaffName(entry.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'Laporan Analitik ORVIX',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.deepOrange,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Periode: ${DateFormat('dd MMM yyyy').format(_range.start)} - ${DateFormat('dd MMM yyyy').format(_range.end)}',
          ),
          pw.SizedBox(height: 18),
          _pdfTable('Ringkasan Metrik', [
            ['Total Hitung', '${history.length}'],
            ['Emas Fisik', '$physical'],
            ['Pivot Point', '$pivot'],
            ['NEST', '$nest'],
          ]),
          pw.SizedBox(height: 18),
          pw.Text(
            'Perbandingan Jenis Perhitungan',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.deepOrange,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SvgImage(
                svg: _pdfDonutSvg(physical, pivot, nest),
                width: 150,
                height: 150,
              ),
              pw.SizedBox(width: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfLegend('Emas Fisik', physical, history.length, '#E75E14'),
                  _pdfLegend('Pivot Point', pivot, history.length, '#5757E8'),
                  _pdfLegend('NEST', nest, history.length, '#0A9B70'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _pdfTable('Performa Staff', [
            ['Staff', 'Perhitungan'],
            ...staffRows
                .take(10)
                .toList()
                .asMap()
                .entries
                .map((entry) => [entry.value.key, '${entry.value.value}']),
          ]),
        ],
      ),
    );
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/laporan_analitik_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await document.save());
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Laporan Analitik ORVIX',
        text: 'Laporan hasil analisis perhitungan ORVIX',
      ),
    );
  }

  pw.Widget _pdfTable(String title, List<List<String>> rows) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: pdf.PdfColors.deepOrange,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: pdf.PdfColors.orange, width: .6),
        children: rows
            .asMap()
            .entries
            .map(
              (entry) => pw.TableRow(
                decoration: entry.key == 0
                    ? const pw.BoxDecoration(color: pdf.PdfColors.orange100)
                    : null,
                children: entry.value
                    .map(
                      (cell) => pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(cell),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    ],
  );

  pw.Widget _pdfLegend(String label, int value, int total, String color) {
    final percentage = total == 0 ? 0.0 : value / total * 100;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            width: 10,
            height: 10,
            color: pdf.PdfColor.fromHex(color),
          ),
          pw.SizedBox(width: 7),
          pw.Text('$label  $value (${percentage.toStringAsFixed(1)}%)'),
        ],
      ),
    );
  }

  String _pdfDonutSvg(int physical, int pivot, int nest) {
    final total = physical + pivot + nest;
    if (total == 0) {
      return '<svg width="150" height="150" viewBox="0 0 150 150"><circle cx="75" cy="75" r="48" fill="none" stroke="#E8E1DC" stroke-width="22"/><circle cx="75" cy="75" r="35" fill="white"/></svg>';
    }

    final segments = [
      (physical, '#E75E14'),
      (pivot, '#5757E8'),
      (nest, '#0A9B70'),
    ];

    final cx = 75.0;
    final cy = 75.0;
    final r = 48.0;
    var currentAngle = -90.0;
    final rendered = <String>[];

    ({double x, double y}) pointForAngle(double angleDegrees) {
      final angleRad = (angleDegrees - 90) * math.pi / 180;
      return (
        x: cx + r * math.cos(angleRad),
        y: cy + r * math.sin(angleRad),
      );
    }

    for (final (value, color) in segments) {
      if (value <= 0) continue;

      final sweepDeg = (value / total) * 360;
      final start = pointForAngle(currentAngle);
      final end = pointForAngle(currentAngle + sweepDeg);
      final largeArc = sweepDeg > 180 ? 1 : 0;
      rendered.add(
        '<path d="M ${start.x.toStringAsFixed(2)} ${start.y.toStringAsFixed(2)} A $r $r 0 $largeArc 1 ${end.x.toStringAsFixed(2)} ${end.y.toStringAsFixed(2)}" fill="none" stroke="$color" stroke-width="22" stroke-linecap="butt"/>',
      );
      currentAngle += sweepDeg;
    }

    return '<svg width="150" height="150" viewBox="0 0 150 150">${rendered.join()}<circle cx="75" cy="75" r="35" fill="white"/></svg>';
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.physical,
    required this.pivot,
    required this.nest,
  });
  final int physical;
  final int pivot;
  final int nest;

  @override
  void paint(Canvas canvas, Size size) {
    final total = (physical + pivot + nest).toDouble();
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final stroke = radius * .38;
    final values = [physical, pivot, nest];
    final colors = [
      const Color(0xFFE75E14),
      const Color(0xFF5757E8),
      const Color(0xFF0A9B70),
    ];
    var start = -1.5708;
    for (var i = 0; i < values.length; i++) {
      final sweep = total == 0 ? 0.0 : values[i] / total * 6.28318;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.physical != physical ||
      oldDelegate.pivot != pivot ||
      oldDelegate.nest != nest;
}
