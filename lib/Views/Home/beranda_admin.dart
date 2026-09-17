import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_histori.dart';
import 'gold_detail.dart';
import 'nest_detail.dart';
import 'pp_detailLGD.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ORVIX Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F6F2),
        fontFamily: 'Sans-Serif',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  DateTime? _timestampFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String _userNameFromMap(Map<String, dynamic> data) {
    return (data['user_name'] ?? data['nama'] ?? data['name'] ?? 'Staff')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: Stack(
        children: [
          // Background Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildMainContent(),
                const SizedBox(height: 100), // Spasi untuk Bottom Navigation
              ],
            ),
          ),
          // Floating Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFDEC2), Color(0xFFFF853C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appbar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                // text_logo beresolusi lebih tinggi sehingga tetap tajam
                // pada ukuran header dibanding orvix_logo.
                'assets/text_logo.png',
                width: 132,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'ORVIX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  // Bell Icon with Badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Profile Avatar
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Greeting Text
          const Text(
            'Selamat Datang, Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau aktivitas dan performa ORVIX hari ini',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN CONTENT SECTION ---
  Widget _buildMainContent() {
    return Container(
      transform: Matrix4.translationValues(0, -16, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ringkasan Sistem
          _buildSectionTitle('Ringkasan Sistem'),
          const SizedBox(height: 12),
          _buildSystemSummaryGrid(),

          const SizedBox(height: 24),

          // 2. Aktivitas Terbaru
          _buildSectionTitle('Aktivitas Terbaru'),
          const SizedBox(height: 12),
          _buildRecentActivitiesCard(),

          const SizedBox(height: 24),

          // 3. Perhitungan Terbaru
          _buildSectionTitle('Perhitungan Terbaru'),
          const SizedBox(height: 12),
          _buildRecentCalculations(),

          const SizedBox(height: 24),

          // 4. Jenis Perhitungan
          _buildSectionTitle('Jenis Perhitungan'),
          const SizedBox(height: 12),
          _buildCalculationTypesCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1E1E),
      ),
    );
  }

  // --- 1. RINGKASAN SISTEM GRID ---
  Widget _buildSystemSummaryGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collectionGroup('calculation_history')
              .snapshots(),
          builder: (context, historySnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('app_usage')
                  .snapshots(),
              builder: (context, usageSnapshot) {
                final users = usersSnapshot.data?.docs ?? const [];
                final histories = historySnapshot.data?.docs ?? const [];
                final usage = usageSnapshot.data?.docs ?? const [];
                final today = DateTime.now();
                final todayKey =
                    '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

                final totalStaff = users.where((doc) {
                  final role = doc.data()['role']?.toString().toLowerCase();
                  return role == 'staff';
                }).length;
                final todayCalculations = histories.where((doc) {
                  final date = _timestampFromMap(doc.data(), [
                    'created_at',
                    'createdAt',
                  ]);
                  return date != null &&
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                }).length;
                final todayUsage = usage.where((doc) {
                  return doc.data()['date']?.toString() == todayKey;
                }).toList();
                final activeStaffToday = todayUsage.length;
                final activityMinutes = todayUsage.fold<int>(
                  0,
                  (total, doc) =>
                      total + ((doc.data()['minutes'] as num?)?.toInt() ?? 0),
                );

                return _buildSummaryCards(
                  totalStaff: totalStaff,
                  activeStaffToday: activeStaffToday,
                  totalCalculations: histories.length,
                  todayCalculations: todayCalculations,
                  activityMinutes: activityMinutes,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required int totalStaff,
    required int activeStaffToday,
    required int totalCalculations,
    required int todayCalculations,
    required int activityMinutes,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.people_alt,
                iconColor: const Color(0xFFEE6C3A),
                iconBg: const Color(0xFFFFF0EB),
                title: 'Total Staff',
                value: '$totalStaff',
                subtext: '$activeStaffToday aktif hari ini',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.calculate,
                iconColor: const Color(0xFFEE6C3A),
                iconBg: const Color(0xFFFFF0EB),
                title: 'Total Perhitungan',
                value: '$totalCalculations',
                subtext: 'total data tercatat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.calendar_today,
                iconColor: const Color(0xFFEE6C3A),
                iconBg: const Color(0xFFFFF0EB),
                title: 'Perhitungan Hari\nIni',
                value: '$todayCalculations',
                subtext: 'tercatat hari ini',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.bolt,
                iconColor: const Color(0xFFEE6C3A),
                iconBg: const Color(0xFFFFF0EB),
                title: 'Aktivitas Hari Ini',
                value: '$activityMinutes',
                subtext: 'menit aktif hari ini',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEE6C3A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    }
    return 'baru saja';
  }

  String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day $month $year';
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // --- 2. AKTIVITAS TERBARU ---
  Widget _buildRecentActivitiesCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, calcSnapshot) {
        final calcDocs =
            (calcSnapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .toList()
              ..sort((a, b) {
                final aDate = _timestampFromMap(a.data(), [
                  'created_at',
                  'createdAt',
                ]);
                final bDate = _timestampFromMap(b.data(), [
                  'created_at',
                  'createdAt',
                ]);
                final aMillis = aDate?.millisecondsSinceEpoch ?? 0;
                final bMillis = bDate?.millisecondsSinceEpoch ?? 0;
                return bMillis.compareTo(aMillis);
              });

        final recentActivities = calcDocs.take(2).map((doc) {
          final data = doc.data();
          final jenis =
              (data['jenis_kalkulator'] ?? data['jenisKalkulator'] ?? '')
                  .toString();
          final user = _userNameFromMap(data);
          final date = _timestampFromMap(data, ['created_at', 'createdAt']);

          return {
            'title': jenis == 'Emas Fisik'
                ? 'Perhitungan Emas Fisik'
                : jenis == 'Pivot Point'
                ? 'Perhitungan Pivot Point'
                : jenis.isEmpty
                ? 'Perhitungan'
                : jenis,
            'subtitle': user.trim().isEmpty ? 'Staff' : user,
            'time': date == null ? 'Belum ada data' : _formatRelativeTime(date),
            'icon': jenis == 'Emas Fisik' ? Icons.calculate : Icons.bar_chart,
            'iconBg': const Color(0xFFFFF0EB),
            'iconColor': const Color(0xFFEE6C3A),
          };
        }).toList();

        final activityTiles = <Widget>[];

        if (recentActivities.isNotEmpty) {
          for (var i = 0; i < recentActivities.length; i++) {
            final item = recentActivities[i];
            activityTiles.add(
              _buildActivityTile(
                icon: item['icon'] as IconData,
                iconBg: item['iconBg'] as Color,
                iconColor: item['iconColor'] as Color,
                title: item['title'] as String,
                subtitle: item['subtitle'] as String,
                time: item['time'] as String,
              ),
            );
            if (i < recentActivities.length - 1) {
              activityTiles.add(
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
              );
            }
          }
        } else {
          activityTiles.add(
            _buildActivityTile(
              icon: Icons.calculate,
              iconBg: const Color(0xFFFFF0EB),
              iconColor: const Color(0xFFEE6C3A),
              title: 'Belum ada perhitungan tercatat',
              subtitle: 'Data masih kosong',
              time: 'Silakan lakukan perhitungan',
            ),
          );
        }

        activityTiles.add(const Divider(height: 1, color: Color(0xFFF3F4F6)));

        activityTiles.add(
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collectionGroup('login_history')
                .snapshots(),
            builder: (context, snapshot) {
              final loginDocs =
                  (snapshot.data?.docs ??
                          const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                      .toList()
                    ..sort((a, b) {
                      final aDate = _timestampFromMap(a.data(), [
                        'logged_in_at',
                        'loggedInAt',
                      ]);
                      final bDate = _timestampFromMap(b.data(), [
                        'logged_in_at',
                        'loggedInAt',
                      ]);
                      final aMillis = aDate?.millisecondsSinceEpoch ?? 0;
                      final bMillis = bDate?.millisecondsSinceEpoch ?? 0;
                      return bMillis.compareTo(aMillis);
                    });
              final latestLogin = loginDocs.isEmpty
                  ? null
                  : loginDocs.first.data();
              final date = latestLogin == null
                  ? null
                  : _timestampFromMap(latestLogin, [
                      'logged_in_at',
                      'loggedInAt',
                    ]);
              final time = date == null
                  ? 'Belum ada login tercatat'
                  : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

              return _buildActivityTile(
                icon: Icons.login_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Login ke sistem',
                subtitle: latestLogin == null
                    ? 'Belum ada data'
                    : _userNameFromMap(latestLogin),
                time: time,
                showChevron: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginHistoryScreen(),
                    ),
                  );
                },
              );
            },
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: activityTiles),
        );
      },
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // --- 3. PERHITUNGAN TERBARU ---
  Widget _buildRecentCalculations() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, snapshot) {
        final docs =
            (snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .toList()
              ..sort((a, b) {
                final aDate = _timestampFromMap(a.data(), [
                  'created_at',
                  'createdAt',
                ]);
                final bDate = _timestampFromMap(b.data(), [
                  'created_at',
                  'createdAt',
                ]);
                return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
                  aDate?.millisecondsSinceEpoch ?? 0,
                );
              });
        final cards = docs.take(2).map((doc) {
          final data = doc.data();
          final jenis =
              (data['jenis_kalkulator'] ?? data['jenisKalkulator'] ?? '')
                  .toString();
          final user = (data['user_name'] ?? data['nama'] ?? 'Staff')
              .toString();
          final timestamp = data['created_at'];
          final date = timestamp is Timestamp ? timestamp.toDate() : null;

          final isGold = jenis == 'Emas Fisik';
          final isPivot = jenis == 'Pivot Point';
          final title = isGold
              ? 'Emas Fisik'
              : isPivot
              ? 'Pivot Point'
              : 'NEST';
          final tagText = isGold
              ? 'Gold'
              : isPivot
              ? 'Chart'
              : 'Nest';
          final tagColor = isGold
              ? const Color(0xFFFEF3C7)
              : const Color(0xFFEFF6FF);
          final tagTextColor = isGold
              ? const Color(0xFFD97706)
              : const Color(0xFF2563EB);

          final info = date == null
              ? '$user  •  Belum ada waktu'
              : '$user  •  ${_formatDateOnly(date)}  •  ${_formatTimeOnly(date)}';

          return {
            'title': title,
            'tagText': tagText,
            'tagColor': tagColor,
            'tagTextColor': tagTextColor,
            'info': info,
            'onTap': () {
              if (jenis == 'Emas Fisik') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const GoldListScreen(),
                  ),
                );
              } else if (jenis == 'Pivot Point') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const PivotPointListScreen(),
                  ),
                );
              } else if (jenis.toLowerCase() == 'nest') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const NestDetailScreen(),
                  ),
                );
              }
            },
            'iconWidget': Container(
              width: jenis == 'Emas Fisik' ? 36 : 40,
              height: jenis == 'Emas Fisik' ? 36 : 40,
              decoration: BoxDecoration(
                color: isGold
                    ? const Color(0xFFEAB308)
                    : isPivot
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGold
                    ? Icons.pie_chart_sharp
                    : isPivot
                    ? Icons.bar_chart
                    : Icons.calculate_rounded,
                color: Colors.white,
                size: isGold ? 20 : 22,
              ),
            ),
            'tagTexts': isPivot ? const ['LGD', 'HSI'] : null,
            'tagBorderColor': isPivot ? const Color(0xFFBFDBFE) : null,
          };
        }).toList();

        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: List.generate(cards.length, (index) {
            final card = cards[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == cards.length - 1 ? 0 : 10,
              ),
              child: _buildCalculationCard(
                iconWidget: card['iconWidget'] as Widget,
                title: card['title'] as String,
                tagText: card['tagText'] as String,
                tagColor: card['tagColor'] as Color,
                tagTextColor: card['tagTextColor'] as Color,
                info: card['info'] as String,
                tagTexts: card['tagTexts'] as List<String>?,
                tagBorderColor: card['tagBorderColor'] as Color?,
                onTap: card['onTap'] as VoidCallback,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCalculationCard({
    required Widget iconWidget,
    required String title,
    required String tagText,
    required Color tagColor,
    required Color tagTextColor,
    required String info,
    List<String>? tagTexts,
    Color? tagBorderColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...((tagTexts ?? [tagText]).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(14),
                              border: tagBorderColor == null
                                  ? null
                                  : Border.all(color: tagBorderColor),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tagTextColor,
                              ),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  // --- 4. AKSES CEPAT ---
  Widget _buildQuickAccess() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAccessTile(
            icon: Icons.groups_rounded,
            title: 'Kelola Staff',
            iconColor: const Color(0xFFEE6C3A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAccessTile(
            icon: Icons.bar_chart_rounded,
            title: 'Analistik',
            iconColor: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessTile({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
        ],
      ),
    );
  }

  // --- 5. JENIS PERHITUNGAN ---
  Widget _buildCalculationTypesCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        int countFor(String type) => docs.where((doc) {
          final data = doc.data();
          return (data['jenis_kalkulator'] ?? data['jenisKalkulator'] ?? '')
                  .toString()
                  .toLowerCase() ==
              type.toLowerCase();
        }).length;

        final counts = [
          countFor('Emas Fisik'),
          countFor('Pivot Point'),
          countFor('NEST'),
        ];
        final total = counts.fold<int>(0, (totalCount, itemCount) {
          return totalCount + itemCount;
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildProgressRow(
                iconWidget: _typeIcon(
                  Icons.pie_chart_sharp,
                  const Color(0xFFEAB308),
                ),
                title: 'Emas Fisik',
                count: '${counts[0]}',
                percentage: _percentage(counts[0], total),
                progress: _progress(counts[0], total),
                progressColor: const Color(0xFFEE6C3A),
              ),
              const SizedBox(height: 16),
              _buildProgressRow(
                iconWidget: _typeIcon(Icons.bar_chart, const Color(0xFF2563EB)),
                title: 'Pivot Point',
                count: '${counts[1]}',
                percentage: _percentage(counts[1], total),
                progress: _progress(counts[1], total),
                progressColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              _buildProgressRow(
                iconWidget: _typeIcon(
                  Icons.calculate_rounded,
                  const Color(0xFF16A34A),
                ),
                title: 'NEST',
                count: '${counts[2]}',
                percentage: _percentage(counts[2], total),
                progress: _progress(counts[2], total),
                progressColor: const Color(0xFF16A34A),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _typeIcon(IconData icon, Color color) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white, size: 16),
  );

  double _progress(int count, int total) => total == 0 ? 0 : count / total;

  String _percentage(int count, int total) =>
      '${(_progress(count, total) * 100).round()}%';

  Widget _buildProgressRow({
    required Widget iconWidget,
    required String title,
    required String count,
    required String percentage,
    required double progress,
    required Color progressColor,
  }) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // --- FLOATING BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFFEE6C3A),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEE6C3A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.bar_chart_rounded, 'Analistik'),
          _buildNavItem(2, Icons.person_rounded, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
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
              color: isSelected
                  ? const Color(0xFFEE6C3A)
                  : Colors.white.withOpacity(0.8),
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
}
