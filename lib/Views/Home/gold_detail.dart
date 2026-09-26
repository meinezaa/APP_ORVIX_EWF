import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daftar Emas Fisik ORVIX',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F6F2),
        fontFamily: 'Sans-Serif',
      ),
      home: const GoldListScreen(),
    );
  }
}

class GoldListScreen extends StatefulWidget {
  const GoldListScreen({super.key});

  @override
  State<GoldListScreen> createState() => _GoldListScreenState();
}

class _GoldListScreenState extends State<GoldListScreen> {
  int _selectedDateIndex = 0;
  bool _hasUserSelectedDate = false;

  String _formatCurrency(double value) {
    final rounded = value.round();
    final digits = rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp $digits';
  }

  List<Map<String, dynamic>> _buildStaffListFromHistory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data();
      final userName = (data['user_name'] ?? data['nama'] ?? 'Staff')
          .toString();
      final name = userName.trim().isEmpty ? 'Staff' : userName;
      final initials = name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0].toUpperCase())
          .join();
      final role = data['role']?.toString().trim().isNotEmpty == true
          ? data['role'].toString()
          : 'Staff';
      final timestamp = data['created_at'];
      final date = timestamp is Timestamp ? timestamp.toDate().toLocal() : null;
      final time = date == null
          ? 'Waktu tidak tersedia'
          : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
      final amount = (data['hasil'] as num?)?.toDouble() ?? 0;
      final colorPairs = [
        {'bg': const Color(0xFFFDE8E0), 'fg': const Color(0xFFD97706)},
        {'bg': const Color(0xFFE0F2FE), 'fg': const Color(0xFF0284C7)},
        {'bg': const Color(0xFFFCE7F3), 'fg': const Color(0xFFDB2777)},
        {'bg': const Color(0xFFF3E8FF), 'fg': const Color(0xFF9333EA)},
        {'bg': const Color(0xFFDCFCE7), 'fg': const Color(0xFF16A34A)},
      ];
      final palette = colorPairs[result.length % colorPairs.length];

      result.add({
        'initials': initials.isEmpty ? 'S' : initials,
        'avatarBg': palette['bg'],
        'avatarTextColor': palette['fg'],
        'name': name,
        'role': role,
        'time': time,
        'amount': _formatCurrency(amount),
      });
    }

    return result;
  }

  String _monthShortName(int month) {
    const names = <String>[
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month];
  }

  String _monthName(int month) {
    const names = <String>[
      '',
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
    ];
    return names[month];
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupByDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in docs) {
      final data = doc.data();
      final value = data['created_at'];
      final date = value is Timestamp ? value.toDate().toLocal() : null;
      if (date == null) continue;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(doc);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final result =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final key in sortedKeys) {
      result[key] = grouped[key]!;
    }
    return result;
  }

  DateTime? _parseKeyDate(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  int _resolveSelectedDateIndex(List<String> dateKeys) {
    if (dateKeys.isEmpty) return 0;

    if (_hasUserSelectedDate) {
      if (_selectedDateIndex >= 0 && _selectedDateIndex < dateKeys.length) {
        return _selectedDateIndex;
      }
      _selectedDateIndex = 0;
      return 0;
    }

    final todayKey = _todayKey();
    final todayIndex = dateKeys.indexOf(todayKey);
    if (todayIndex != -1) {
      return todayIndex;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, snapshot) {
        final allDocs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final docs =
            allDocs.where((doc) {
              final data = doc.data();
              final jenis =
                  (data['jenis_kalkulator'] ?? data['jenisKalkulator'] ?? '')
                      .toString();
              return jenis == 'Emas Fisik';
            }).toList()..sort((a, b) {
              final aDate = a.data()['created_at'] is Timestamp
                  ? (a.data()['created_at'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.data()['created_at'] is Timestamp
                  ? (b.data()['created_at'] as Timestamp).toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
        final grouped = _groupByDate(docs);
        final dateKeys = grouped.keys.toList();
        final selectedDateIndex = _resolveSelectedDateIndex(dateKeys);
        final selectedDateKey = dateKeys.isNotEmpty
            ? dateKeys[selectedDateIndex]
            : _todayKey();
        final selectedDocs =
            grouped[selectedDateKey] ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final staffList = _buildStaffListFromHistory(selectedDocs.toList());
        final selectedDate = _parseKeyDate(selectedDateKey);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildDateFilterCard(grouped, dateKeys, selectedDateKey),
                  const SizedBox(height: 16),
                  _buildSummaryBanner(selectedDocs.toList(), selectedDate),
                  const SizedBox(height: 24),
                  _buildStaffSectionHeader(),
                  const SizedBox(height: 12),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: staffList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      return _buildStaffCard(staff);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        Column(
          children: const [
            Text(
              'PERHITUNGAN ORVIX',
              style: TextStyle(
                color: Color(0xFFEE6C3A),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Daftar Emas Fisik',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 1. FILTER TANGGAL CARD ---
  Widget _buildDateFilterCard(
    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped,
    List<String> dateKeys,
    String? selectedDateKey,
  ) {
    final chips = dateKeys.take(3).toList();
    final date = selectedDateKey == null
        ? _parseKeyDate(_todayKey())
        : _parseKeyDate(selectedDateKey);
    final monthLabel = date == null
        ? 'Tidak ada data'
        : '${_monthName(date.month)} ${date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFFEE6C3A),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TANGGAL TERPILIH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEE6C3A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(chips.length, (index) {
              final key = chips[index];
              final date = _parseKeyDate(key);
              final count = grouped[key]?.length ?? 0;
              final label = date == null
                  ? 'Data'
                  : '${date.day} ${_monthShortName(date.month)} ($count)';
              final isSelected = selectedDateKey == key;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    final targetIndex = dateKeys.indexOf(key);
                    if (targetIndex >= 0) {
                      setState(() {
                        _selectedDateIndex = targetIndex;
                        _hasUserSelectedDate = true;
                      });
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index == chips.length - 1 ? 0 : 8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEE6C3A)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFF3F4F6),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  const SizedBox(width: 6),
                  Text(
                    'Total ${selectedDateKey == null ? 0 : (grouped[selectedDateKey]?.length ?? 0)} Perhitungan Tercatat',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              Text(
                selectedDateKey == null
                    ? 'Belum ada data'
                    : () {
                        final date = _parseKeyDate(selectedDateKey);
                        if (date == null) return 'Belum ada data';
                        return '${_dayName(date.weekday)}, ${date.day} ${_monthShortName(date.month)}';
                      }(),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dayName(int weekday) {
    const names = <String>[
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return names[weekday];
  }

  // --- 2. RINGKASAN HARI INI (GRADIENT BANNER) ---
  Widget _buildSummaryBanner(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime? selectedDate,
  ) {
    final totalSesi = docs.length;
    final totalBerat = docs.fold<double>(0, (total, doc) {
      final data = doc.data();
      final value =
          (data['jumlah_emas'] as num?)?.toDouble() ??
          (data['hasil'] as num?)?.toDouble() ??
          0;
      return total + value;
    });
    final labelDate = selectedDate == null
        ? 'Belum ada data'
        : '${selectedDate.day} ${_monthShortName(selectedDate.month)} ${selectedDate.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEE6C3A), Color(0xFFF39256)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEE6C3A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'RINGKASAN HARI INI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Emas Fisik (EWF)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labelDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Sesi Perhitungan',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalSesi Sesi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Berat Dihitung',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalBerat.round()} Gram',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. SECTION HEADER ---
  Widget _buildStaffSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Staf Pelaksana',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        InkWell(
          onTap: () {},
          child: Row(
            children: const [
              Text(
                'Urutkan Waktu',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEE6C3A),
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.arrow_downward_rounded,
                size: 12,
                color: Color(0xFFEE6C3A),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 4. STAFF CARD TILE ---
  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar Inisial
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: staff['avatarBg'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    staff['initials'],
                    style: TextStyle(
                      color: staff['avatarTextColor'],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Staff Name & Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          staff['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Emas Fisik',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff['role'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              // Time
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    staff['time'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // Result Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hasil Perhitungan',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                staff['amount'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEE6C3A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
