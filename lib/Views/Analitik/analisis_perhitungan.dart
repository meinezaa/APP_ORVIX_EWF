import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Models/historikalkulator_model.dart';
import '../../Services/history_service.dart';

class AnalisisPerhitunganView extends StatefulWidget {
  const AnalisisPerhitunganView({super.key});

  @override
  State<AnalisisPerhitunganView> createState() =>
      _AnalisisPerhitunganViewState();
}

class _AnalisisPerhitunganViewState extends State<AnalisisPerhitunganView> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedRange;
  String _searchText = '';

  static const _orange = Color(0xFFF26422);
  static const _blue = Color(0xFF4385F4);
  static const _purple = Color(0xFF7657D9);
  static const _pageBackground = Color(0xFFFFF9F4);

  @override
  void dispose() {
    _searchController.dispose();
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

  List<HistoryModel> _filterHistory(List<HistoryModel> history) {
    final query = _searchText.trim().toLowerCase();
    return history.where((item) {
      final inRange =
          _selectedRange == null ||
          (!item.createdAt.isBefore(_selectedRange!.start) &&
              !item.createdAt.isAfter(
                _selectedRange!.end.add(const Duration(days: 1)),
              ));
      final matchesSearch =
          query.isEmpty || item.jenisKalkulator.toLowerCase().contains(query);
      return inRange && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: StreamBuilder<List<HistoryModel>>(
          stream: HistoryService.watchHistory(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Gagal memuat analisis: ${snapshot.error}'),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _orange),
              );
            }

            final history = _filterHistory(snapshot.data ?? const []);
            return _buildContent(history);
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<HistoryModel> history) {
    final physical = history.where((item) => _isPhysical(item)).length;
    final pivot = history.length - physical;
    final total = history.length;
    final physicalRate = total == 0 ? 0.0 : physical / total * 100;
    final pivotRate = total == 0 ? 0.0 : pivot / total * 100;
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        'Pengguna';

    return RefreshIndicator(
      color: _orange,
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildFilters(),
          const SizedBox(height: 12),
          _buildSummaryCards(total, physical, pivot, physicalRate, pivotRate),
          const SizedBox(height: 16),
          _buildTrendCard(history),
          const SizedBox(height: 16),
          _buildBreakdownCard(physical, pivot, total, physicalRate, pivotRate),
          const SizedBox(height: 16),
          _buildPerformanceCard(history, userName),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Analisis Perhitungan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: _orange),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final rangeText = _selectedRange == null
        ? 'Bulan ini'
        : '${DateFormat('dd MMM').format(_selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)}';
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Cari jenis perhitungan...',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildSummaryCards(
    int total,
    int physical,
    int pivot,
    double physicalRate,
    double pivotRate,
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
          'Rata-rata per Hari',
          _averagePerDay(total).toStringAsFixed(1),
          'Periode terpilih',
          _purple,
          Icons.timeline_rounded,
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
          Row(
            children: const [
              _Legend(color: _orange, label: 'Emas Fisik'),
              SizedBox(width: 18),
              _Legend(color: _blue, label: 'Pivot Point'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: CustomPaint(painter: _LineChartPainter(values)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    int physical,
    int pivot,
    int total,
    double physicalRate,
    double pivotRate,
  ) {
    return _panel(
      title: 'Perbandingan Jenis Perhitungan',
      trailing: 'Total $total',
      child: Row(
        children: [
          SizedBox(
            width: 145,
            height: 145,
            child: CustomPaint(painter: _DonutChartPainter(physical, pivot)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _breakdownRow(_orange, 'Emas Fisik', physical, physicalRate),
                const SizedBox(height: 18),
                _breakdownRow(_blue, 'Pivot Point', pivot, pivotRate),
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

  Widget _buildPerformanceCard(List<HistoryModel> history, String userName) {
    final count = history.length;
    final maxValue = count == 0 ? 1 : count;
    return _panel(
      title: 'Performa Staff',
      trailing: 'Periode terpilih',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _orange.withValues(alpha: .15),
                  child: const Icon(Icons.person, color: _orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$count perhitungan pada periode ini',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: count / maxValue,
              minHeight: 7,
              color: _orange,
              backgroundColor: const Color(0xFFFFE7DA),
            ),
          ),
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

  double _averagePerDay(int total) {
    if (_selectedRange == null) return total.toDouble();
    final days = _selectedRange!.duration.inDays + 1;
    return days == 0 ? total.toDouble() : total / days;
  }

  List<List<double>> _dailyValues(List<HistoryModel> history) {
    final now = DateTime.now();
    final physical = List<double>.filled(7, 0);
    final pivot = List<double>.filled(7, 0);
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
        (_isPhysical(item) ? physical : pivot)[index]++;
      }
    }
    return [physical, pivot];
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
          text: '${(4 - i) * 25}',
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
    final max = series
        .expand((line) => line)
        .fold<double>(1, (value, item) => item > value ? item : value);
    final colors = [
      _AnalisisPerhitunganViewState._orange,
      _AnalisisPerhitunganViewState._blue,
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
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series;
}

class _DonutChartPainter extends CustomPainter {
  final int first;
  final int second;
  const _DonutChartPainter(this.first, this.second);

  @override
  void paint(Canvas canvas, Size size) {
    final total = first + second;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 9;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = const Color(0xFFEAF0FA);
    canvas.drawCircle(center, radius, base);
    if (total == 0) return;
    var start = -1.5708;
    for (final data in [first, second]) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 24
        ..color = data == first
            ? _AnalisisPerhitunganViewState._orange
            : _AnalisisPerhitunganViewState._blue;
      final sweep = data / total * 6.2832;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
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
      oldDelegate.first != first || oldDelegate.second != second;
}
