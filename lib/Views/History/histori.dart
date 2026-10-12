import 'package:flutter/material.dart';
import '../../Models/historikalkulator_model.dart';
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
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String _selectedCalculator = 'Semua Kalkulator';
  final Set<String> _selectedHistoryIds = {};
  bool _isDeleting = false;
  bool _isSelectionMode = false;

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
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/text_logo.png', width: 92),
                    const SizedBox(width: 8),
                    Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
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
                      initialData: const <HistoryModel>[],
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Histori belum dapat dimuat.'),
                          );
                        }

                        final allHistory = snapshot.data ?? [];
                        final history = _deduplicateCalculationHistory(
                          allHistory,
                        );
                        final filteredHistory = _filterHistory(history);
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                          children: [
                            _buildFilters(),
                            const SizedBox(height: 12),
                            _buildSelectionToolbar(filteredHistory, allHistory),
                            const SizedBox(height: 8),
                            if (filteredHistory.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Text(
                                    DateUtils.isSameDay(
                                          _selectedDate,
                                          DateTime.now(),
                                        )
                                        ? 'Hari ini tidak ada perhitungan.'
                                        : 'Tidak ada perhitungan pada ${_formatDate(_selectedDate)}.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...filteredHistory.map(
                                (item) => _buildHistoryCard(item, allHistory),
                              ),
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

  List<HistoryModel> _deduplicateCalculationHistory(
    List<HistoryModel> history,
  ) {
    final uniqueHistory = <HistoryModel>[];
    for (final item in history) {
      if (uniqueHistory.any(item.isSameCalculationAs)) continue;
      uniqueHistory.add(item);
    }
    return uniqueHistory;
  }

  Widget _buildFilters() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0C5A8)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Perhitungan Hari Ini' : 'Pilih Tanggal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pilih tanggal',
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar_outlined),
                  ),
                ],
              ),
            ),
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
              DropdownMenuItem(value: 'NEST', child: Text('NEST')),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateUtils.dateOnly(picked);
      _selectedHistoryIds.clear();
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

  Widget _buildSelectionToolbar(
    List<HistoryModel> visibleHistory,
    List<HistoryModel> allHistory,
  ) {
    final visibleIds = <String>{
      for (final item in visibleHistory)
        ..._matchingHistoryIds(item, allHistory),
    };
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedHistoryIds.contains);
    return Row(
      children: [
        TextButton.icon(
          onPressed: visibleIds.isEmpty
              ? null
              : () => setState(() {
                  if (allVisibleSelected) {
                    _selectedHistoryIds.removeAll(visibleIds);
                    _isSelectionMode = false;
                  } else {
                    _selectedHistoryIds.addAll(visibleIds);
                    _isSelectionMode = true;
                  }
                }),
          icon: Icon(
            allVisibleSelected ? Icons.deselect : Icons.select_all,
            size: 19,
          ),
          label: Text(allVisibleSelected ? 'Batalkan' : 'Pilih semua'),
          style: TextButton.styleFrom(foregroundColor: primaryOrange),
        ),
        const Spacer(),
        if (_selectedHistoryIds.isNotEmpty) ...[
          Text('${_selectedHistoryIds.length} dipilih'),
          IconButton(
            tooltip: 'Hapus riwayat terpilih',
            onPressed: _deleteSelectedHistory,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade700,
          ),
        ],
      ],
    );
  }

  Set<String> _matchingHistoryIds(
    HistoryModel history,
    List<HistoryModel> allHistory,
  ) {
    return allHistory
        .where((item) => item.isSameCalculationAs(history))
        .map((item) => item.id)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  void _toggleHistorySelection(
    HistoryModel history,
    List<HistoryModel> allHistory,
  ) {
    final ids = _matchingHistoryIds(history, allHistory);
    setState(() {
      if (ids.any(_selectedHistoryIds.contains)) {
        _selectedHistoryIds.removeAll(ids);
        if (_selectedHistoryIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedHistoryIds.addAll(ids);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelectedHistory() async {
    if (_selectedHistoryIds.isEmpty || _isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus riwayat?'),
        content: Text(
          'Hapus ${_selectedHistoryIds.length} riwayat perhitungan terpilih?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _isDeleting = true;
    try {
      await HistoryService.deleteCalculations(_selectedHistoryIds);
      if (!mounted) return;
      setState(() {
        _selectedHistoryIds.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat berhasil dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Riwayat gagal dihapus.')));
    } finally {
      _isDeleting = false;
    }
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

  List<HistoryModel> _filterHistory(List<HistoryModel> history) {
    return history.where((item) {
      final matchesDate = DateUtils.isSameDay(item.createdAt, _selectedDate);
      final matchesCalculator =
          _selectedCalculator == 'Semua Kalkulator' ||
          item.jenisKalkulator == _selectedCalculator;
      return matchesDate && matchesCalculator;
    }).toList();
  }

  Widget _buildHistoryCard(
    HistoryModel history,
    List<HistoryModel> allHistory,
  ) {
    final date = history.createdAt;
    final matchingIds = _matchingHistoryIds(history, allHistory);
    final isSelected = matchingIds.any(_selectedHistoryIds.contains);
    final dateText =
        '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _toggleHistorySelection(history, allHistory),
        onTap: _selectedHistoryIds.isNotEmpty
            ? () => _toggleHistorySelection(history, allHistory)
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailHistoryScreen(history: history),
                ),
              ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFE2D1) : cardBgColor,
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
                children: [
                  if (_isSelectionMode) ...[
                    SizedBox(
                      width: 34,
                      height: 30,
                      child: IgnorePointer(
                        child: Checkbox(
                          value: isSelected,
                          visualDensity: VisualDensity.compact,
                          activeColor: primaryOrange,
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    history.jenisKalkulator,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                  const Spacer(),
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
