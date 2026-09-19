import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KelolaStaffContent extends StatefulWidget {
  const KelolaStaffContent({super.key});

  @override
  State<KelolaStaffContent> createState() => _KelolaStaffContentState();
}

class RiwayatPerhitunganStaffPage extends StatefulWidget {
  const RiwayatPerhitunganStaffPage({super.key, required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  State<RiwayatPerhitunganStaffPage> createState() =>
      _RiwayatPerhitunganStaffPageState();
}

class _RiwayatPerhitunganStaffPageState
    extends State<RiwayatPerhitunganStaffPage> {
  static const _types = ['Semua', 'Emas Fisik', 'Pivot Point', 'NEST'];
  String _selectedType = 'Semua';

  String _textValue(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _calculationType(Map<String, dynamic> data) {
    final rawType = _textValue(data, [
      'jenis_kalkulator',
      'jenisKalkulator',
      'jenis_perhitungan',
      'type',
    ], fallback: '');
    final type = rawType.toLowerCase();
    if (type.contains('nest')) return 'NEST';
    if (type.contains('pivot')) return 'Pivot Point';
    if (type.contains('emas') || type.contains('fisik')) return 'Emas Fisik';
    return rawType.isEmpty ? 'Emas Fisik' : rawType;
  }

  String _pivotCategory(Map<String, dynamic> data) {
    const keys = [
      'kategori',
      'category',
      'kategori_pivot',
      'pivot_category',
      'selectedCategory',
      'selected_category',
      'market',
      'symbol',
      'kode_kategori',
      'kodeKategori',
      'instrument',
      'asset',
      'jenis_asset',
    ];
    for (final key in keys) {
      final value = data[key]?.toString().trim().toUpperCase() ?? '';
      if (value.contains('LGD')) return 'LGD';
      if (value.contains('HSI')) return 'HSI';
    }
    return 'Belum tersimpan';
  }

  String _resultValue(Map<String, dynamic> data) {
    final value = data['hasil'] ?? data['hasil_akhir'] ?? data['result'];
    return _formatResultNumber(
      value is num ? value.toString() : value?.toString() ?? '0',
    );
  }

  String _formatResultNumber(String value) {
    final normalized = value.replaceAll(',', '.');
    final rawParts = normalized.split('.');
    final integer = rawParts.first;
    final rawDecimal = rawParts.length > 1 ? rawParts.sublist(1).join() : '';
    final decimal = rawDecimal.substring(0, rawDecimal.length.clamp(0, 2));
    final trimmedDecimal = decimal.replaceFirst(RegExp(r'0+$'), '');
    final trimmed = trimmedDecimal.isEmpty
        ? integer
        : '$integer.$trimmedDecimal';
    final parts = trimmed.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final integerPart = sign.isEmpty ? parts.first : parts.first.substring(1);
    final groupedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final decimalPart = parts.length > 1 ? parts.sublist(1).join() : '';
    return '$sign$groupedInteger${decimalPart.isEmpty ? '' : ',$decimalPart'}';
  }

  DateTime _dateTimeValue(Map<String, dynamic> data) {
    final value = data['created_at'] ?? data['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _dateValue(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
    }
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}';
      }
      return value.trim();
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final staffData = widget.document.data();
    final staffName = staffData['nama'] ?? staffData['name'] ?? 'Staff';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),
      appBar: AppBar(
        title: Text(
          'Riwayat - $staffName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.document.id)
            .collection('calculation_history')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF26422)),
            );
          }

          final docs = [...snapshot.data?.docs ?? []]
            ..sort(
              (a, b) =>
                  _dateTimeValue(b.data()).compareTo(_dateTimeValue(a.data())),
            );
          final filteredDocs = _selectedType == 'Semua'
              ? docs
              : docs
                    .where(
                      (doc) => _calculationType(doc.data()) == _selectedType,
                    )
                    .toList();

          return Column(
            children: [
              _buildTypeFilters(),
              if (docs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Belum ada riwayat perhitungan untuk staff ini.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else if (filteredDocs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Belum ada riwayat pada kategori ini.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data();
                      final jenis = _calculationType(data);
                      final pivotCategory = jenis == 'Pivot Point'
                          ? _pivotCategory(data)
                          : '';
                      final tanggal = _dateValue(
                        data['created_at'] ?? data['createdAt'],
                      );
                      final status = (data['status'] ?? 'Sukses').toString();
                      final hasilAkhir = _resultValue(data);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE8E1DC)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPerhitunganPage(
                                  historyData: data,
                                  staffName: staffName,
                                  tanggal: tanggal,
                                ),
                              ),
                            );
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.assessment_rounded,
                              color: Color(0xFFF26422),
                            ),
                          ),
                          title: Text(
                            jenis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (pivotCategory.isNotEmpty) ...[
                                Text(
                                  'Kategori: $pivotCategory',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7D6B63),
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              Text(
                                tanggal,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hasil: $hasilAkhir',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF26422),
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8FAF2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF149F5B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: _types.map((type) {
          final selected = type == _selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type),
              selected: selected,
              onSelected: (_) => setState(() => _selectedType = type),
              selectedColor: const Color(0xFFF26422),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF6D625D),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              side: const BorderSide(color: Color(0xFFE8E1DC)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DetailPerhitunganPage extends StatelessWidget {
  const DetailPerhitunganPage({
    super.key,
    required this.historyData,
    required this.staffName,
    required this.tanggal,
  });

  final Map<String, dynamic> historyData;
  final String staffName;
  final String tanggal;

  @override
  Widget build(BuildContext context) {
    final jenis = _calculationType;
    final status = (historyData['status'] ?? 'Sukses').toString();
    final hasilAkhir = _historyText([
      'hasil',
      'hasil_akhir',
      'result',
    ], fallback: '0');

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),
      appBar: AppBar(
        title: const Text(
          'Detail Perhitungan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(jenis, status),
          const SizedBox(height: 12),
          _buildStaffInfo(),
          const SizedBox(height: 16),
          if (_isPhysical)
            _buildPhysicalDetail(hasilAkhir)
          else if (_isPivot)
            _buildPivotDetail(hasilAkhir)
          else
            _buildNestDetail(hasilAkhir),
        ],
      ),
    );
  }

  String get _calculationType {
    final rawType = _historyText([
      'jenis_kalkulator',
      'jenisKalkulator',
      'jenis_perhitungan',
      'type',
    ], fallback: 'Emas Fisik');
    final lowerType = rawType.toLowerCase();
    if (lowerType.contains('nest')) return 'NEST';
    if (lowerType.contains('pivot')) return 'Pivot Point';
    return 'Emas Fisik';
  }

  bool get _isPhysical => _calculationType == 'Emas Fisik';
  bool get _isPivot => _calculationType == 'Pivot Point';

  Widget _buildHeader(String jenis, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF26422),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JENIS PERHITUNGAN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jenis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FAF2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF149F5B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Staff Penginput',
                      style: TextStyle(fontSize: 10, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: const Color(0xFFE8E1DC)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanggal,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        'Waktu Input',
                        style: TextStyle(fontSize: 10, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalDetail(String hasilAkhir) {
    final h1 = _historyText(['harga_beli_per_gram', 'hargaBeliPerGram']);
    final h2 = _historyText(['harga_jual_per_gram', 'hargaJualPerGram']);
    final h3 = _historyText(['selisih_per_gram', 'selisihPerGram']);
    final h4 = _historyText(['jumlah_emas', 'jumlahEmas']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Parameter Input'),
        _parameterCard([
          [
            'ToZ',
            _historyText(['toz']),
          ],
          [
            'Kurs',
            _historyText(['kurs']),
          ],
          [
            'Modal',
            _historyText(['modal']),
          ],
          [
            'Harga Beli',
            _historyText(['harga_beli', 'hargaBeli']),
          ],
          [
            'Harga Jual',
            _historyText(['harga_jual', 'hargaJual']),
          ],
        ]),
        const SizedBox(height: 16),
        _resultCard(hasilAkhir),
        const SizedBox(height: 16),
        _buildPhysicalSteps(h1, h2, h3, h4, hasilAkhir),
      ],
    );
  }

  Widget _buildPivotDetail(String hasilAkhir) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Parameter Input'),
        _parameterCard([
          ['Kategori', _pivotCategoryForDetail()],
          [
            'Open',
            _historyText(['open']),
          ],
          [
            'High',
            _historyText(['high']),
          ],
          [
            'Low',
            _historyText(['low']),
          ],
          [
            'Close',
            _historyText(['close']),
          ],
        ]),
        const SizedBox(height: 16),
        _buildIndicationCard(hasilAkhir),
      ],
    );
  }

  Widget _buildNestDetail(String hasilAkhir) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Parameter Input'),
        _parameterCard([
          [
            'Open',
            _historyText(['open']),
          ],
          [
            'Close',
            _historyText(['close']),
          ],
        ]),
        const SizedBox(height: 16),
        _buildIndicationCard(hasilAkhir),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  Widget _parameterCard(List<List<String>> rows) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _parameterRow(row[0], row[1]),
              ),
              if (entry.key != rows.length - 1)
                const Divider(height: 1, color: Color(0xFFF0EBE6)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _resultCard(String hasilAkhir) {
    return _buildIndicationCard(hasilAkhir, title: 'Hasil Akhir');
  }

  Widget _buildIndicationCard(String hasilAkhir, {String title = 'INDIKASI'}) {
    final indication = _historyText(['indikasi'], fallback: '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _parameterRow(
            'Hasil Akhir',
            title == 'INDIKASI' ? hasilAkhir : 'Rp $hasilAkhir',
          ),
          if (title == 'INDIKASI' && indication.isNotEmpty) ...[
            const SizedBox(height: 16),
            _indicationButton(indication),
          ],
        ],
      ),
    );
  }

  Widget _indicationButton(String indication) {
    final isBuy = indication.toLowerCase() == 'buy';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isBuy ? const Color(0xFFE8FFF5) : const Color(0xFFFFEEEE),
        border: Border.all(
          color: isBuy ? const Color(0xFF56D6A5) : const Color(0xFFE88989),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        indication.toUpperCase(),
        style: TextStyle(
          color: isBuy ? const Color(0xFF078A63) : const Color(0xFFC14444),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPhysicalSteps(
    String h1,
    String h2,
    String h3,
    String h4,
    String hasilAkhir,
  ) {
    final hargaBeli = _historyText(['harga_beli', 'hargaBeli']);
    final hargaJual = _historyText(['harga_jual', 'hargaJual']);
    final kurs = _historyText(['kurs']);
    final toz = _historyText(['toz']);
    final modal = _historyText(['modal']);
    return Column(
      children: [
        _tahapCard(
          '1',
          'Tahap 1',
          'Perhitungan Awal',
          'HB x Kurs / ToZ = $hargaBeli x $kurs / $toz',
          h1,
        ),
        _tahapCard(
          '2',
          'Tahap 2',
          'Perhitungan Kedua',
          'HJ x Kurs / ToZ = $hargaJual x $kurs / $toz',
          h2,
        ),
        _tahapCard(
          '3',
          'Tahap 3',
          'Perhitungan Ketiga',
          'H2 - H1 = $h2 - $h1',
          h3,
        ),
        _tahapCard(
          '4',
          'Tahap 4',
          'Perhitungan Keempat',
          'Modal / H1 = $modal / $h1',
          h4,
        ),
        _tahapCard(
          '5',
          'Tahap 5',
          'Hasil Akhir',
          'H3 x H4 = $h3 x $h4',
          hasilAkhir,
          isFinal: true,
        ),
      ],
    );
  }

  String _historyText(List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = historyData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        if (value is num) return _formatStoredNumber(key, value);
        return value.toString();
      }
    }
    return fallback;
  }

  String _pivotCategoryForDetail() {
    const keys = [
      'kategori',
      'category',
      'kategori_pivot',
      'pivot_category',
      'selectedCategory',
      'selected_category',
      'market',
      'symbol',
      'kode_kategori',
      'kodeKategori',
      'instrument',
      'asset',
      'jenis_asset',
    ];
    for (final key in keys) {
      final value = historyData[key]?.toString().trim().toUpperCase() ?? '';
      if (value.contains('LGD')) return 'LGD';
      if (value.contains('HSI')) return 'HSI';
    }
    return 'Belum tersimpan';
  }

  String _formatStoredNumber(String key, num value) {
    final normalizedKey = key.toLowerCase();
    if (normalizedKey == 'toz' || normalizedKey == 'jumlah_emas') {
      return value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '')
          .replaceAll('.', ',');
    }
    if (normalizedKey == 'kurs' ||
        normalizedKey == 'modal' ||
        normalizedKey == 'harga_beli' ||
        normalizedKey == 'harga_jual' ||
        normalizedKey.contains('per_gram') ||
        normalizedKey == 'selisih_per_gram' ||
        (normalizedKey == 'hasil' && _isPhysical)) {
      return _formatThousands(value.round().toString());
    }
    return value.toStringAsFixed(2);
  }

  String _formatThousands(String value) {
    final sign = value.startsWith('-') ? '-' : '';
    final digits = sign.isEmpty ? value : value.substring(1);
    return sign +
        digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  Widget _parameterRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Color(0xFFF26422)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _tahapCard(
    String stepNumber,
    String title,
    String subtitle,
    String formula,
    String result, {
    bool isFinal = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFF26422),
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  formula,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '= $result',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isFinal ? const Color(0xFFF26422) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _staffEmailText({
  required String userId,
  required String fallback,
  TextStyle? style,
}) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('login_history')
        .snapshots(),
    builder: (context, snapshot) {
      final loginEmails = (snapshot.data?.docs ?? const [])
          .map((doc) {
            final data = doc.data();
            return (data['email'] ??
                    data['user_email'] ??
                    data['email_address'] ??
                    '')
                .toString()
                .trim();
          })
          .where((email) => email.isNotEmpty)
          .toList();
      final email = fallback == '-' && loginEmails.isNotEmpty
          ? loginEmails.last
          : fallback;
      return Text(email, style: style);
    },
  );
}

class DetailStaffPage extends StatelessWidget {
  const DetailStaffPage({super.key, required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  String _text(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String? _photo(Map<String, dynamic> data) {
    final value =
        data['foto_profil_path'] ?? data['photoUrl'] ?? data['photoURL'];
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  bool _active(Map<String, dynamic> data) =>
      data['isActive'] != false &&
      data['aktif'] != false &&
      (data['status'] ?? '').toString().toLowerCase() != 'inactive' &&
      (data['status'] ?? '').toString().toLowerCase() != 'nonaktif';

  String _dateValue(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}';
      }
      return value.trim();
    }
    return '-';
  }

  DateTime? _timestampFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(document.id)
          .snapshots(),
      builder: (context, profileSnapshot) {
        final data = profileSnapshot.data?.data() ?? document.data();
        final name = _text(data, ['nama', 'name'], fallback: 'Nama staff');
        final photo = _photo(data);
        final initials = name
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0])
            .join()
            .toUpperCase();
        final statusText = _active(data) ? 'Aktif' : 'Nonaktif';

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(document.id)
              .collection('calculation_history')
              .snapshots(),
          builder: (context, historySnapshot) {
            final histories = historySnapshot.data?.docs ?? const [];
            final profileEmail = _text(data, [
              'email',
              'user_email',
              'email_address',
            ], fallback: '-');
            final historyEmail = histories
                .map((doc) => doc.data()['email']?.toString().trim() ?? '')
                .firstWhere((email) => email.isNotEmpty, orElse: () => '-');
            final displayEmail = profileEmail == '-'
                ? historyEmail
                : profileEmail;
            final total = histories.length;
            final today = DateTime.now();
            final todayCount = histories.where((doc) {
              final created = _timestampFromMap(doc.data(), [
                'created_at',
                'createdAt',
              ]);
              return created != null &&
                  created.year == today.year &&
                  created.month == today.month &&
                  created.day == today.day;
            }).length;

            return Scaffold(
              backgroundColor: const Color(0xFFFFF9F4),
              appBar: AppBar(
                title: const Text(
                  'Detail Staff',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.black87,
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF26422),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1AF26422),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFFFF0E5),
                          backgroundImage: photo == null
                              ? null
                              : NetworkImage(photo),
                          child: photo == null
                              ? Text(
                                  initials.isEmpty ? 'S' : initials,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    color: Color(0xFFF26422),
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D1D1D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text(data, ['role'], fallback: 'Staff'),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _staffEmailText(
                          userId: document.id,
                          fallback: displayEmail,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text(data, [
                            'phone',
                            'nomor_telepon',
                            'phone_number',
                          ], fallback: '-'),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailRow(
                    'Tanggal Lahir',
                    _dateValue(
                      data['tanggal_lahir'] ??
                          data['birthDate'] ??
                          data['tanggalLahir'],
                    ),
                    icon: Icons.calendar_today_outlined,
                  ),
                  _detailRow(
                    'Jenis Kelamin',
                    _text(data, [
                      'jenis_kelamin',
                      'gender',
                      'jenisKelamin',
                    ], fallback: '-'),
                    icon: Icons.person_outline,
                  ),
                  _detailRow(
                    'Role',
                    _text(data, ['role'], fallback: 'Staff'),
                    icon: Icons.badge_outlined,
                  ),
                  _detailRow(
                    'Status',
                    statusText,
                    icon: Icons.verified_user_outlined,
                    valueColor: _active(data)
                        ? const Color(0xFF149F5B)
                        : const Color(0xFFE34A4A),
                    valueBg: _active(data)
                        ? const Color(0xFFE8FAF2)
                        : const Color(0xFFFFEEEE),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RiwayatPerhitunganStaffPage(document: document),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history_rounded, color: Color(0xFFF26422)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Riwayat Perhitungan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Lihat semua riwayat perhitungan staff ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E1DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Perhitungan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF26422),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E1DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Perhitungan Hari Ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$todayCount',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF26422),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditStaffPage(document: document),
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF26422),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Edit Staff',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    IconData? icon,
    Color valueColor = const Color(0xFF1F1F1F),
    Color valueBg = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFFF26422), size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                ),
              ],
            ),
          ),
          if (label == 'Status')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: valueBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EditStaffPage extends StatefulWidget {
  const EditStaffPage({super.key, required this.document});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  @override
  State<EditStaffPage> createState() => _EditStaffPageState();
}

class _EditStaffPageState extends State<EditStaffPage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _birthDate;
  late final TextEditingController _gender;
  late final TextEditingController _role;
  late String _status;

  @override
  void initState() {
    super.initState();
    final data = widget.document.data();
    _name = TextEditingController(
      text: (data['nama'] ?? data['name'] ?? '').toString(),
    );
    _email = TextEditingController(
      text: (data['email'] ?? data['user_email'] ?? data['email_address'] ?? '')
          .toString(),
    );
    _phone = TextEditingController(
      text: (data['phone'] ?? data['nomor_telepon'] ?? '').toString(),
    );
    _birthDate = TextEditingController(
      text:
          (data['tanggal_lahir'] ??
                  data['birthDate'] ??
                  data['tanggalLahir'] ??
                  '')
              .toString(),
    );
    _gender = TextEditingController(
      text:
          (data['jenis_kelamin'] ??
                  data['gender'] ??
                  data['jenisKelamin'] ??
                  '')
              .toString(),
    );
    _role = TextEditingController(text: 'Staff');
    _status = _active(data) ? 'Aktif' : 'Nonaktif';
  }

  bool _active(Map<String, dynamic> data) =>
      data['isActive'] != false &&
      data['aktif'] != false &&
      (data['status'] ?? '').toString().toLowerCase() != 'inactive' &&
      (data['status'] ?? '').toString().toLowerCase() != 'nonaktif';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _birthDate.dispose();
    _gender.dispose();
    _role.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final isActive = _status == 'Aktif';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.document.id)
        .update({
          'nama': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'tanggal_lahir': _birthDate.text.trim(),
          'jenis_kelamin': _gender.text.trim(),
          'role': 'staff',
          'status': isActive ? 'active' : 'inactive',
          'isActive': isActive,
          'aktif': isActive,
        });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data();
    final photo =
        data['foto_profil_path'] ?? data['photoUrl'] ?? data['photoURL'];
    final photoUrl = photo?.toString().trim();
    final initials = (_name.text.trim().isEmpty ? 'S' : _name.text.trim())
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),
      appBar: AppBar(
        title: const Text(
          'Edit Detail Staff',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8E1DC)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFFFF0E5),
                  backgroundImage: photoUrl == null || photoUrl.isEmpty
                      ? null
                      : NetworkImage(photoUrl),
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          initials.isEmpty ? 'S' : initials,
                          style: const TextStyle(
                            color: Color(0xFFF26422),
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _name.text.trim().isEmpty ? 'Nama staff' : _name.text.trim(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _field('Nama Lengkap', _name, icon: Icons.person_outline),
          _field('Email', _email, icon: Icons.email_outlined),
          _field('Nomor Telepon', _phone, icon: Icons.phone_outlined),
          _field(
            'Tanggal Lahir',
            _birthDate,
            icon: Icons.calendar_today_outlined,
          ),
          _field('Jenis Kelamin', _gender, icon: Icons.wc_outlined),
          _field('Role', _role, icon: Icons.badge_outlined),
          _toggleField(
            label: 'Status',
            value: _status,
            options: const ['Aktif', 'Nonaktif'],
            onChanged: (value) => setState(() => _status = value ?? _status),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF26422),
                    side: const BorderSide(color: Color(0xFFF26422)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF26422),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      decoration: _decoration(label, icon: icon),
    ),
  );

  Widget _toggleField({
    required String label,
    required String value,
    IconData? icon,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    const inactiveBorder = Color(0xFFE8E1DC);
    const inactiveText = Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = value == option;
              final isStatus = label == 'Status';
              final optionBg = isSelected
                  ? (isStatus
                        ? const Color(0xFFEAFBF1)
                        : const Color(0xFFFFF0E8))
                  : Colors.white;
              final optionBorder = isSelected
                  ? (isStatus
                        ? const Color(0xFF32B76A)
                        : const Color(0xFFF26422))
                  : inactiveBorder;
              final optionTextColor = isSelected
                  ? (isStatus
                        ? const Color(0xFF32B76A)
                        : const Color(0xFFF26422))
                  : inactiveText;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 0 ? 8 : 0,
                    left: index == 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: optionBg,
                        border: Border.all(color: optionBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null && option == value) ...[
                            Icon(
                              icon,
                              size: 18,
                              color: label == 'Status'
                                  ? const Color(0xFF32B76A)
                                  : const Color(0xFFF26422),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: optionTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFFF26422), size: 18)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF26422), width: 1.2),
        ),
      );
}

class _KelolaStaffContentState extends State<KelolaStaffContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _sortMode = 'nameAsc';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Gagal memuat staff: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF26422)),
          );
        }

        final staff = (snapshot.data?.docs ?? const [])
            .where((doc) => _isStaff(doc.data()))
            .where((doc) => _hasName(doc.data()))
            .where((doc) => _matchesSearch(doc.data()))
            .toList();
        _sortStaff(staff);

        return Column(
          children: [
            _buildSearch(),
            const SizedBox(height: 12),
            if (staff.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 42),
                child: Text('Belum ada staff yang sesuai.'),
              )
            else
              ...staff.map(_buildStaffCard),
          ],
        );
      },
    );
  }

  bool _isStaff(Map<String, dynamic> data) =>
      (data['role'] ?? 'staff').toString().toLowerCase() != 'admin';

  bool _hasName(Map<String, dynamic> data) =>
      (data['nama'] ?? data['name'] ?? '').toString().trim().isNotEmpty;

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return true;
    final name = (data['nama'] ?? data['name'] ?? '').toString().toLowerCase();
    return name.contains(query) ||
        _emailFrom(data).toLowerCase().contains(query);
  }

  String _emailFrom(Map<String, dynamic> data) =>
      (data['email'] ?? data['user_email'] ?? data['email_address'] ?? '-')
          .toString();

  String? _photoUrlFrom(Map<String, dynamic> data) {
    final value =
        data['foto_profil_path'] ?? data['photoUrl'] ?? data['photoURL'];
    final url = value?.toString().trim();
    return url == null || url.isEmpty ? null : url;
  }

  bool _isActive(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    return data['isActive'] != false &&
        data['aktif'] != false &&
        status != 'inactive' &&
        status != 'nonaktif';
  }

  void _sortStaff(List<QueryDocumentSnapshot<Map<String, dynamic>>> staff) {
    staff.sort((a, b) {
      final first = a.data();
      final second = b.data();
      if (_sortMode == 'active' || _sortMode == 'inactive') {
        final firstActive = _isActive(first) ? 1 : 0;
        final secondActive = _isActive(second) ? 1 : 0;
        return _sortMode == 'active'
            ? secondActive.compareTo(firstActive)
            : firstActive.compareTo(secondActive);
      }
      final result = (first['nama'] ?? first['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo(
            (second['nama'] ?? second['name'] ?? '').toString().toLowerCase(),
          );
      return _sortMode == 'nameDesc' ? -result : result;
    });
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchText = value),
      decoration: InputDecoration(
        hintText: 'Cari nama atau email',
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.tune_rounded, color: Colors.black54),
          onSelected: (value) => setState(() => _sortMode = value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'nameAsc', child: Text('Nama (A-Z)')),
            const PopupMenuItem(value: 'nameDesc', child: Text('Nama (Z-A)')),
            const PopupMenuItem(
              value: 'active',
              child: Text('Prioritas Aktif'),
            ),
            const PopupMenuItem(
              value: 'inactive',
              child: Text('Prioritas Nonaktif'),
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF26422), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildStaffCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['nama'] ?? data['name'] ?? 'Staff').toString();
    final email = _emailFrom(data);
    final photoUrl = _photoUrlFrom(data);
    final active = _isActive(data);
    final initials = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E1DC)),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailStaffPage(document: doc)),
          );
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF0E5),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  initials.isEmpty ? 'S' : initials,
                  style: const TextStyle(
                    color: Color(0xFFF26422),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: _staffEmailText(
          userId: doc.id,
          fallback: email,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE8FAF2)
                    : const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                active ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? const Color(0xFF149F5B)
                      : const Color(0xFFE34A4A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF26422),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
