import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Models/histori_model.dart';
import '../../Models/users_model.dart';
import '../../Services/auth_services.dart';
import '../../Services/history_service.dart';
import '../Auth/login.dart';
import 'detail_profil.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3A06D),
            Color(0xFFF8C29E),
            Color(0xFFFFE8D8),
            Color(0xFFFFF8F3),
          ],
          stops: [0.0, 0.38, 0.68, 1.0],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<List<HistoryModel>>(
          stream: HistoryService.watchHistory(),
          builder: (context, historySnapshot) {
            final history = historySnapshot.data ?? const <HistoryModel>[];
            final counts = _countCalculations(history);
            return StreamBuilder<UserModel?>(
              stream: _watchUser(),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildIdentityCard(user),
                    const SizedBox(height: 18),
                    _buildTipCard(),
                    const SizedBox(height: 14),
                    _buildUsageChart(),
                    const SizedBox(height: 30),
                    _buildSummary(counts),
                    const SizedBox(height: 66),
                    _buildLogoutButton(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Stream<UserModel?> _watchUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return data == null ? null : UserModel.fromMap(data);
        });
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/text_logo.png', width: 88),
              const SizedBox(width: 10),
              const Text('Profil', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            ],
          ),
          Positioned(right: 0, child: _roundIcon(Icons.settings_outlined)),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0E7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF241A17), size: 25),
    );
  }

  Widget _buildIdentityCard(UserModel? user) {
    final name = user?.nama.isNotEmpty == true ? user!.nama : 'Pengguna ORVIX';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : (FirebaseAuth.instance.currentUser?.email ?? '-');
    final photoPath = user?.fotoProfilPath;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DetailProfilView()),
      ),
      borderRadius: BorderRadius.circular(15),
      child: _panel(
        padding: const EdgeInsets.all(18),
        color: Colors.white.withValues(alpha: 0.72),
        child: Row(
          children: [
          ClipOval(
            child: SizedBox(
              width: 70,
              height: 70,
              child: photoPath != null && photoPath.isNotEmpty
                  ? Image.file(File(photoPath), fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF192D4B),
                      alignment: Alignment.center,
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 28),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF594D48),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Bergabung sejak', style: TextStyle(fontSize: 11, color: Color(0xFF766D68))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: Color(0xFFE75D1C),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _monthYear(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD4B7), Color(0xFFFFE9DB)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 6, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Hitung '),
                          TextSpan(
                            text: 'Emas Fisik & Pivot\nPoint',
                            style: TextStyle(color: Color(0xFFE75D1C)),
                          ),
                          TextSpan(text: ' dengan mudah'),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Gunakan kalkulator ORVIX untuk perhitungan yang cepat, akurat, dan terpercaya.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF766D68)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Image.asset('assets/pict_profil.png', fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    return StreamBuilder<List<int>>(
      stream: _watchUsage(),
      builder: (context, snapshot) {
        final values = snapshot.data ?? List<int>.filled(5, 0);
        const maxValue = 60;
        return _panel(
          padding: const EdgeInsets.fromLTRB(20, 15, 18, 12),
          color: Colors.white.withValues(alpha: 0.78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Terakhir Kemarin',
                    style: TextStyle(
                      color: Color(0xFF8D1710),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'menit',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(height: 142, child: CustomPaint(painter: _UsageChartPainter(values: values, maxValue: maxValue), size: Size.infinite)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(Map<String, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFFE75D1C), size: 19),
            SizedBox(width: 5),
            Text(
              'Ringkasan Aktivitas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryCard(
              Icons.calculate,
              'Total Perhitungan',
              '${counts['total']}',
            ),
            const SizedBox(width: 10),
            _summaryCard(Icons.balance, 'Emas Fisik', '${counts['emas']}'),
            const SizedBox(width: 10),
            _summaryCard(Icons.show_chart, 'Pivot Point', '${counts['pivot']}'),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB17F), Color(0xFFFFE4D1)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: Colors.black),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFC84F15),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF716761)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() => InkWell(
    onTap: _logout,
    borderRadius: BorderRadius.circular(12),
    child: _panel(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      child: const Row(
        children: [
          Icon(Icons.logout, color: Color(0xFFD82222)),
          SizedBox(width: 18),
          Text(
            'Keluar',
            style: TextStyle(
              color: Color(0xFF716761),
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Icon(Icons.chevron_right, size: 28),
        ],
      ),
    ),
  );

  Widget _panel({required Widget child, required EdgeInsets padding, Color? color}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFFFF8F3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Map<String, int> _countCalculations(List<HistoryModel> history) => {
    'total': history.length,
    'emas': history
        .where((item) => item.jenisKalkulator.toLowerCase().contains('emas'))
        .length,
    'pivot': history
        .where((item) => item.jenisKalkulator.toLowerCase().contains('pivot'))
        .length,
  };

  Stream<List<int>> _watchUsage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(List<int>.filled(5, 0));
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('app_usage')
        .orderBy('date', descending: true)
        .limit(7)
        .snapshots()
        .map((snapshot) {
          final usageByWeekday = List<int>.filled(5, 0);
          for (final doc in snapshot.docs) {
            final date = DateTime.tryParse(doc.id);
            if (date == null || date.weekday > 5) continue;
            usageByWeekday[date.weekday - 1] =
                (doc.data()['minutes'] as num?)?.toInt() ?? 0;
          }
          return usageByWeekday;
        });
  }

  String _monthYear(DateTime date) => '${_monthName(date.month)} ${date.year}';
  String _monthName(int month) => const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ][month - 1];
}

class AppUsageTracker {
  static Timer? _timer;

  static void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _recordMinute());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _recordMinute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('app_usage')
        .doc(date)
        .set({
          'date': date,
          'minutes': FieldValue.increment(1),
        }, SetOptions(merge: true));
  }
}

class _UsageChartPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;

  const _UsageChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    const chartTop = 8.0;
    const chartBottom = 112.0;
    const labelWidth = 28.0;
    const barColor = Color(0xFFE97B40);
    final chartWidth = size.width - labelWidth;
    final guidePaint = Paint()
      ..color = const Color(0xFF6C6866)
      ..strokeWidth = 1.3;
    final barPaint = Paint()..color = barColor;

    const guideSpacing = 34.0;
    for (var guideIndex = 0; guideIndex < 3; guideIndex++) {
      final minute = [60, 30, 15][guideIndex];
      final y = chartTop + (guideSpacing * guideIndex);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), guidePaint);
      _drawText(canvas, '$minute', Offset(chartWidth + 7, y - 8));
    }

    final slotWidth = chartWidth / 5;
    for (var index = 0; index < 5; index++) {
      final value = values[index].clamp(0, maxValue);
      final barHeight = value == 0 ? 3.0 : (chartBottom - chartTop) * value / maxValue;
      final barWidth = slotWidth * 0.38;
      final left = (slotWidth * index) + ((slotWidth - barWidth) / 2);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, chartBottom - barHeight, barWidth, barHeight),
          topLeft: const Radius.circular(11),
          topRight: const Radius.circular(11),
        ),
        barPaint,
      );
      _drawText(canvas, _dayLabel(index), Offset(left + (barWidth / 2) - 11, chartBottom + 11));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF16110F), fontSize: 12, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  String _dayLabel(int index) => const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'][index];

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}
