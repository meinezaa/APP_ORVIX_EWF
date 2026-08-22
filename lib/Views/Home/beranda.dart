import 'package:flutter/material.dart';
import '../../models/gold_data.dart';
import '../../Services/api_services.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedNavIndex = 0;

  // Tanggal Filter Default (MM/DD/YYYY)
  DateTime? _startDate = DateTime(2026, 7, 8); // 8 Juli 2026
  DateTime? _endDate = DateTime(2026, 8, 20); // 20 Agustus 2026

  List<GoldHistory> _rawHistoricalData = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1. Ambil seluruh data dari slide 1 hingga slide terakhir
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getGoldHistory(maxPages: 10);
      setState(() {
        _rawHistoricalData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

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

      if (cleanStr.contains('-')) {
        return DateTime.parse(cleanStr);
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

    // Urutkan dari tanggal terlama ke terbaru (Ascending) agar Juli muncul paling atas
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
        _currentPage = 1; // Reset ke halaman 1 setiap ganti filter
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxPagesToShow = _totalPages > 4 ? 4 : _totalPages;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: 'Halo, ',
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFFD36A28),
                            fontWeight: FontWeight.normal,
                          ),
                          children: [
                            TextSpan(
                              text: 'Meineza!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA6A6A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Siap melakukan perhitungan hari ini?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E8E82),
                        ),
                      ),
                    ],
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
                        child: Icon(Icons.person, color: Color(0xFFD36A28)),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE3D5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              text: 'Hitung dengan ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E1A0C),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Cepat ',
                                  style: TextStyle(color: Color(0xFFD36A28)),
                                ),
                                TextSpan(text: 'dan '),
                                TextSpan(
                                  text: 'Akurat',
                                  style: TextStyle(color: Color(0xFFD36A28)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ORVIX membantu perhitungan emas fisik dan pivot poin lebih mudah',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6E5544),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Icon(
                        Icons.calculate_rounded,
                        size: 70,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // HISTORICAL DATA HEADER & FILTER TANGGAL
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
                  const Text(
                    'Historical Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Start  ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(child: _buildDateField(true)),
                  const SizedBox(width: 10),
                  const Text(
                    'End  ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(child: _buildDateField(false)),
                ],
              ),

              const SizedBox(height: 16),

              // TABEL DATA
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E0D8)),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Open',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'High',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Low',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      data.date,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      data.open.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      data.high.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      data.low.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      data.close.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // PAGINASI TABEL
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

              const SizedBox(height: 24),

              // RINGKASAN AKTIVITAS
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD36A28),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ringkasan Aktivitas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    '12',
                    'Total\nPerhitungan',
                    Icons.grid_view_rounded,
                    const Color(0xFFFCE1D1),
                  ),
                  _buildStatCard(
                    '7',
                    'Emas Fisik',
                    Icons.format_list_bulleted_sharp,
                    const Color(0xFFFCE1D1),
                  ),
                  _buildStatCard(
                    '5',
                    'Pivot Point',
                    Icons.show_chart,
                    const Color(0xFFFCE1D1),
                  ),
                  _buildStatCard(
                    '+12%',
                    'DARI KEMARIN',
                    Icons.trending_up,
                    const Color(0xFFE2F0D9),
                    isGreen: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          BottomNavigationBar(
            currentIndex: _selectedNavIndex,
            onTap: (index) => setState(() => _selectedNavIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFD36A28),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: SizedBox(height: 24),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate_outlined),
                label: 'Calculate',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
          ),
          Positioned(
            top: -18,
            left: MediaQuery.of(context).size.width / 8 - 28,
            child: GestureDetector(
              onTap: () => setState(() => _selectedNavIndex = 0),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD36A28),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Color(0xFFD36A28),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildStatCard(
    String val,
    String title,
    IconData icon,
    Color bgColor, {
    bool isGreen = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGreen ? Colors.green.shade200 : const Color(0xFFE8E0D8),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isGreen ? Colors.green : Colors.black87,
                ),
                if (!isGreen) ...[
                  const SizedBox(width: 4),
                  Text(
                    val,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isGreen ? val : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isGreen ? FontWeight.bold : FontWeight.normal,
                color: isGreen ? Colors.green : Colors.black87,
              ),
            ),
            if (isGreen)
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 7, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
