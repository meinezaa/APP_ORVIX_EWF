import 'package:flutter/material.dart';
import '../../Models/histori_model.dart';
import '../../Services/history_service.dart';
import 'detail_histori.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color primaryOrange = Color(0xFFDC6B38);
  static const Color cardBgColor = Color(0xFFEFEFEF);
  static const Color cardBorderColor = Color(0xFFCCCCCC);
  String? _selectedPeriod;
  String _selectedCalculator = 'Semua Kalkulator';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEA8648), Color(0xFFFDF7F2)],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/text_logo.png', width: 92),
                    const SizedBox(width: 8),
                    const Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: StreamBuilder<List<HistoryModel>>(
                      stream: HistoryService.watchHistory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: primaryOrange,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Histori belum dapat dimuat.'),
                          );
                        }

                        final history = snapshot.data ?? [];
                        if (history.isEmpty) {
                          return const Center(
                            child: Text(
                              'Belum ada aktivitas perhitungan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final periods = _buildPeriods(history);
                        final filteredHistory = _filterHistory(history);
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          children: [
                            _buildFilters(periods),
                            const SizedBox(height: 18),
                            if (filteredHistory.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'Belum ada histori pada periode ini.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              ...filteredHistory.map(_buildHistoryCard),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(Map<String, String> periods) {
    final selectedValue = periods.containsKey(_selectedPeriod)
        ? _selectedPeriod
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0C5A8)),
      ),
      child: Column(
        children: [
          _buildDropdownRow(
            icon: Icons.calendar_month_outlined,
            label: 'Periode',
            value: selectedValue,
            hint: 'Semua Bulan',
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua Bulan'),
              ),
              ...periods.entries.map(
                (period) => DropdownMenuItem<String?>(
                  value: period.key,
                  child: Text(period.value),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedPeriod = value),
          ),
          const Divider(height: 1),
          _buildDropdownRow(
            icon: Icons.calculate_outlined,
            label: 'Jenis',
            value: _selectedCalculator,
            hint: 'Semua Kalkulator',
            items: const [
              DropdownMenuItem(
                value: 'Semua Kalkulator',
                child: Text('Semua Kalkulator'),
              ),
              DropdownMenuItem(
                value: 'Pivot Point',
                child: Text('Pivot Point'),
              ),
              DropdownMenuItem(value: 'Emas Fisik', child: Text('Emas Fisik')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCalculator = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryOrange, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              hint: Text(hint),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _buildPeriods(List<HistoryModel> history) {
    final periods = <String, String>{};
    for (final item in history) {
      final key = _periodKey(item.createdAt);
      periods[key] =
          '${_monthName(item.createdAt.month)} ${item.createdAt.year}';
    }
    return Map.fromEntries(
      periods.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  List<HistoryModel> _filterHistory(List<HistoryModel> history) {
    return history.where((item) {
      final matchesPeriod =
          _selectedPeriod == null ||
          _periodKey(item.createdAt) == _selectedPeriod;
      final matchesCalculator =
          _selectedCalculator == 'Semua Kalkulator' ||
          item.jenisKalkulator == _selectedCalculator;
      return matchesPeriod && matchesCalculator;
    }).toList();
  }

  String _periodKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Widget _buildHistoryCard(HistoryModel history) {
    final date = history.createdAt;
    final dateText =
        '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailHistoryScreen(history: history),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    history.jenisKalkulator,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                  Text(
                    dateText,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Hasil: ${history.hasil.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
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
