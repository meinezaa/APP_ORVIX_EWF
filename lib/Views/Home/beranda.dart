import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Models/gold_data.dart';
import '../../Models/histori_model.dart';
import '../../Models/users_model.dart';
import '../../Services/api_services.dart';
import '../../Services/history_service.dart';
import '../History/detail_histori.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onViewAllHistory;

  const HomeView({super.key, this.onViewAllHistory});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Tanggal Filter Default (MM/DD/YYYY)
  DateTime? _startDate = DateTime(2026, 7, 8); // 8 Juli 2026
  DateTime? _endDate = DateTime(2026, 8, 20); // 20 Agustus 2026

  List<GoldHistory> _rawHistoricalData = [];
  bool _isLoading = false;
  String? _loadError;
  int _currentPage = 1;
  final int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1. Ambil seluruh data dari slide 1 hingga slide terakhir[cite: 1]
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await ApiService.getGoldHistory(maxPages: 10);
      setState(() {
        _rawHistoricalData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError =
            'Data historical gagal dimuat. Periksa koneksi lalu coba lagi.';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  // 2. Parser Teks Tanggal ("08 Jul 2026" / "12 Aug 2026" -> DateTime)[cite: 1]
  Widget _buildTableCell(String value, {bool isHeader = false}) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: isHeader
              ? TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF211A17),
                )
              : TextStyle(
                  fontFamily: 'sans-serif-medium',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF302A27),
                ),
        ),
      ),
    );
  }

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

    const months = [
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // 3. Filter Data Berdasarkan Rentang Tanggal yang Dipilih User[cite: 1]
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

      // Hanya simpan data di antara Start dan End[cite: 1]
      list = list.where((item) {
        DateTime? dt = _parseDate(item.date);
        if (dt == null) return false;
        return !dt.isBefore(start) && !dt.isAfter(end);
      }).toList();
    }

    // Urutkan dari tanggal terlama ke terbaru (Ascending) agar Juli muncul paling atas[cite: 1]
    list.sort((a, b) {
      DateTime? dtA = _parseDate(a.date);
      DateTime? dtB = _parseDate(b.date);
      if (dtA == null || dtB == null) return 0;
      return dtA.compareTo(dtB);
    });

    return list;
  }

  // 4. Paginasi Tampilan Aplikasi[cite: 1]
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
        } else {
          _endDate = picked;
        }
        _currentPage = 1; // Reset ke halaman 1 setiap ganti filter[cite: 1]
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final maxPagesToShow = _totalPages > 4 ? 4 : _totalPages;

    return StreamBuilder<UserModel?>(
      stream: _watchUser(),
      builder: (context, snapshot) {
        final name = snapshot.data?.nama.trim();
        final displayName = name == null || name.isEmpty ? 'Pengguna' : name;

        return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 250,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF2A674), Color(0xFFFFF8F3)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              width: 92,
                              fit: BoxFit.contain,
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.black87,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFE8E0D8),
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFFD36A28),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: 'Halo, ',
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 22,
                              color: Color(0xFFD36A28),
                              fontWeight: FontWeight.normal,
                            ),
                            children: [
                              TextSpan(
                                text: '$displayName!',
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
                          'Siap melakukan perhitungan hari ini?',
                          style: TextStyle(
                            fontFamily: 'sans-serif-medium',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9E4E27),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BANNER[cite: 1]
                  Container(
                    width: double.infinity,
                    height: 146,
                    padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFFFF0D9), Color(0xFFE9B18F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                                  text: 'Hitung dengan ',
                                  style: TextStyle(
                                    fontFamily: 'sans-serif',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E1A0C),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Cepat ',
                                      style: TextStyle(
                                        fontFamily: 'sans-serif',
                                        color: const Color(0xFFD36A28),
                                      ),
                                    ),
                                    TextSpan(text: 'dan '),
                                    TextSpan(
                                      text: 'Akurat',
                                      style: TextStyle(
                                        fontFamily: 'sans-serif',
                                        color: const Color(0xFFD36A28),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ORVIX membantu perhitungan emas fisik dan pivot poin lebih mudah',
                                style: TextStyle(
                                  fontFamily: 'sans-serif-medium',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6E5544),
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

                  const SizedBox(height: 24),

                  // HISTORICAL DATA HEADER & FILTER TANGGAL[cite: 1]
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
                        'Historical Data',
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF211A17),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Start  ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(child: _buildDateField(true)),
                      const SizedBox(width: 10),
                      const Text(
                        'End  ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(child: _buildDateField(false)),
                    ],
                  ),
                  if (_dateRangeNotice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _dateRangeNotice!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A5A3B),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // TABEL DATA (Realtime API)[cite: 1]
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E0D8)),
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
                            color: const Color(0xFFEAEAEA),
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
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD36A28),
                                ),
                              )
                            : _loadError != null
                            ? Padding(
                                padding: const EdgeInsets.all(20.0),
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
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Tidak ada data pada rentang tanggal yang dipilih',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Column(
                                children: _paginatedData.map((data) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 7,
                                        ),
                                        child: Row(
                                          children: [
                                            _buildTableCell(
                                              _formatDisplayDate(data.date),
                                            ),
                                            _buildTableCell(
                                              data.open.toStringAsFixed(2),
                                            ),
                                            _buildTableCell(
                                              data.high.toStringAsFixed(2),
                                            ),
                                            _buildTableCell(
                                              data.low.toStringAsFixed(2),
                                            ),
                                            _buildTableCell(
                                              data.close.toStringAsFixed(2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.black.withValues(
                                          alpha: 0.14,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PAGINASI TABEL[cite: 1]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPageBtn('<<', onTap: () => _goToPage(1)),
                      _buildPageBtn(
                        '<',
                        onTap: () => _goToPage(_currentPage - 1),
                      ),
                      for (int i = 1; i <= maxPagesToShow; i++)
                        _buildPageBtn(
                          '$i',
                          isActive: _currentPage == i,
                          onTap: () => _goToPage(i),
                        ),
                      _buildPageBtn(
                        '>',
                        onTap: () => _goToPage(_currentPage + 1),
                      ),
                      _buildPageBtn('>>', onTap: () => _goToPage(_totalPages)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // PERHITUNGAN TERAKHIR[cite: 1]
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
                          const Text(
                            'Perhitungan Terakhir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onViewAllHistory,
                        child: const Text(
                          'Lihat Semua >',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD36A28),
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
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Belum ada perhitungan.',
                              style: TextStyle(color: Colors.grey),
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
      },
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
          color: Colors.white,
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
                color: date == null ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E0D8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.jenisKalkulator,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD36A28),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hasil: ${history.hasil.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Text(
                dateText,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
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
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
