import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PivotPointLiveView extends StatefulWidget {
  const PivotPointLiveView({
    super.key,
    required this.category,
    required this.onLgd,
    required this.onHsi,
  });

  final String category;
  final VoidCallback onLgd;
  final VoidCallback onHsi;

  @override
  State<PivotPointLiveView> createState() => _PivotPointLiveViewState();
}

class _PivotPointLiveViewState extends State<PivotPointLiveView> {
  String? _selectedDate;

  dynamic _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data[key] != null) return data[key];
    }
    return null;
  }

  String _text(Map<String, dynamic> data, List<String> keys, String fallback) {
    final value = _value(data, keys)?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  DateTime? _date(Map<String, dynamic> data) {
    final value = _value(data, ['created_at', 'createdAt']);
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    return null;
  }

  double _number(Map<String, dynamic> data) {
    final value = _value(data, ['hasil', 'pivot_point', 'pivotPoint']);
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, snapshot) {
        final docs =
            (snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where((doc) {
                  final data = doc.data();
                  return _text(data, [
                            'jenis_kalkulator',
                            'jenisKalkulator',
                          ], '').toLowerCase() ==
                          'pivot point' &&
                      _text(data, ['kategori', 'category'], '').toLowerCase() ==
                          widget.category.toLowerCase();
                })
                .toList()
              ..sort(
                (a, b) => (_date(b.data()) ?? DateTime(1970)).compareTo(
                  _date(a.data()) ?? DateTime(1970),
                ),
              );

        final grouped =
            <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
        for (final doc in docs) {
          final date = _date(doc.data());
          if (date != null) grouped.putIfAbsent(_key(date), () => []).add(doc);
        }
        final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        final today = _key(DateTime.now());
        final selected = dates.contains(_selectedDate)
            ? _selectedDate!
            : dates.contains(today)
            ? today
            : dates.isEmpty
            ? today
            : dates.first;
        final selectedDocs =
            grouped[selected] ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final average = selectedDocs.isEmpty
            ? 0.0
            : selectedDocs
                      .map((doc) => _number(doc.data()))
                      .reduce((a, b) => a + b) /
                  selectedDocs.length;
        final selectedDate = DateTime.tryParse(selected);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F2),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text(
                              'PERHITUNGAN ORVIX',
                              style: TextStyle(
                                color: Color(0xFFEE6C3A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Daftar Pivot Point',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _tab('LGD', widget.category == 'LGD', widget.onLgd),
                      _tab('HSI', widget.category == 'HSI', widget.onHsi),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _dateCard(dates, selected, grouped),
                  const SizedBox(height: 16),
                  _summary(selectedDocs, average, selectedDate),
                  const SizedBox(height: 22),
                  Text(
                    'Daftar Staf Pelaksana (${widget.category})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...selectedDocs.map(_staffCard),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEE6C3A) : const Color(0xFFEFECE6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _dateCard(
    List<String> dates,
    String selected,
    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Row(
          children: const [
            Icon(Icons.calendar_today_outlined, color: Color(0xFFEE6C3A)),
            SizedBox(width: 8),
            Text(
              'TANGGAL TERPILIH',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (dates.isEmpty)
          const Text('Belum ada data Pivot Point untuk kategori ini.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates.map((key) {
                final date = DateTime.parse(key);
                final active = key == selected;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFEE6C3A)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${date.day} ${DateFormat('MMM', 'id_ID').format(date)} (${grouped[key]!.length})',
                      style: TextStyle(
                        color: active ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${grouped[selected]?.length ?? 0} Perhitungan Selesai',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat(
                'EEEE, d MMM yyyy',
                'id_ID',
              ).format(DateTime.parse(selected)),
              style: const TextStyle(color: Colors.black45),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    double average,
    DateTime? date,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFFEE6C3A), Color(0xFFF39256)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RINGKASAN ${date == null ? '' : DateFormat('d MMM yyyy', 'id_ID').format(date)}',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Pivot Point (${widget.category})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                '${docs.length} Sesi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${NumberFormat('#,##0.00').format(average)} Poin',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _staffCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = _text(data, ['user_name', 'nama', 'displayName'], 'Staff');
    final date = _date(data);
    final action = _text(data, ['indikasi', 'actionType'], '-').toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(name[0].toUpperCase())),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _text(data, ['role'], 'Staff'),
                      style: const TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
              Text(date == null ? '-' : DateFormat('HH:mm').format(date)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pivot Point: ${NumberFormat('#,##0.00').format(_number(data))}',
                style: const TextStyle(
                  color: Color(0xFFC25E38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                action,
                style: TextStyle(
                  color: action == 'BUY' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
