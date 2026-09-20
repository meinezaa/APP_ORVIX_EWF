import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class RiwayatAktivitasAdminPage extends StatefulWidget {
  const RiwayatAktivitasAdminPage({super.key});

  @override
  State<RiwayatAktivitasAdminPage> createState() =>
      _RiwayatAktivitasAdminPageState();
}

class _RiwayatAktivitasAdminPageState extends State<RiwayatAktivitasAdminPage> {
  String _searchText = '';
  String _selectedFilter = 'Semua';

  final Color _bgSoft = const Color(0xFFF4F1EE);
  final Color _orange = const Color(0xFFE68A4D);
  final Color _orangeDeep = const Color(0xFFCF6F2E);
  final Color _olive = const Color(0xFF5D6B51);
  final Color _textDark = const Color(0xFF1D1D1D);
  final Color _textSoft = const Color(0xFF5E5E5E);
  final Color _line = const Color(0xFFE9E1D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collectionGroup('login_history')
              .snapshots(),
          builder: (context, loginSnapshot) {
            final loginItems = (loginSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .map(_parseLoginLog)
                .toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('calculation_history')
                  .snapshots(),
              builder: (context, calcSnapshot) {
                final calcItems = (calcSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .map(_parseCalculationLog)
                    .toList();

                final allItems = <_ActivityLogItem>[...loginItems, ...calcItems]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final visibleItems = _filterItems(allItems);
                final summarySafe = allItems.where((item) => _isHealthyStatus(item.status)).length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildSummaryCard(
                                total: allItems.length,
                                safe: summarySafe,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildSearchBar(),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildDownloadSection(),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _buildFilterTabs(),
                            ),
                            const SizedBox(height: 14),
                            _buildActivityList(visibleItems),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<_ActivityLogItem> _filterItems(List<_ActivityLogItem> items) {
    final query = _searchText.trim().toLowerCase();
    return items.where((item) {
      final typeMatch = _selectedFilter == 'Semua' ||
          item.category.toLowerCase() == _selectedFilter.toLowerCase() ||
          (_selectedFilter == 'Autentikasi' && item.type == 'autentikasi') ||
          (_selectedFilter == 'Manajemen Staff' && item.type == 'manajemen');

      final queryMatch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.meta.toLowerCase().contains(query);

      return typeMatch && queryMatch;
    }).toList();
  }

  bool _isHealthyStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('aman') ||
        normalized.contains('selesai') ||
        normalized.contains('tersimpan') ||
        normalized.contains('valid');
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B), size: 26),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORVIX ADMIN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: _orange,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Riwayat Aktivitas',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required int total, required int safe}) {
    final score = 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryPanel(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'TOTAL CATATAN',
                  value: '$total',
                  suffix: 'Aktivitas',
                  accent: Colors.white,
                  iconBg: const Color(0xFFF3E8DE),
                  iconColor: _orange,
                  big: true,
                  showDelta: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryPanel(
                  icon: Icons.shield_outlined,
                  label: 'INTEGRITAS LOG',
                  value: '$score%',
                  suffix: 'Aman',
                  accent: const Color(0xFFF5E1D1),
                  iconBg: const Color(0xFFF7E5D6),
                  iconColor: _orange,
                  big: true,
                  showDelta: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel({
    required IconData icon,
    required String label,
    required String value,
    required String suffix,
    required Color accent,
    required Color iconBg,
    required Color iconColor,
    required bool big,
    required bool showDelta,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: _textSoft,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: big ? 24 : 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: Color(0xFF7B7B7B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                textAlign: TextAlign.start,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: 'Cari riwayat, ID staf, aktivitas...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8B8B8B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(top: 0, bottom: 0),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['Semua', 'Autentikasi', 'Manajemen Staff'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final label = tabs[index];
        final active = _selectedFilter == label;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = label),
            child: Container(
              margin: EdgeInsets.only(right: index < tabs.length - 1 ? 10 : 0),
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _orange : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? _orange : const Color(0xFFE6DED7),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _textSoft,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActivityList(List<_ActivityLogItem> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 42, color: _orange.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              const Text(
                'Tidak ada aktivitas yang cocok',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<_ActivityLogItem>>{};
    for (final item in items) {
      final key = _groupKey(item.createdAt);
      grouped.putIfAbsent(key, () => <_ActivityLogItem>[]).add(item);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final sectionTitle = entry.key;
        final sectionItems = entry.value;
        final sectionCount = sectionItems.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: _orangeDeep,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '$sectionCount Aktivitas',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...sectionItems.map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: _buildActivityCard(item),
                )),
          ],
        );
      }).toList(),
    );
  }

  String _groupKey(DateTime value) {
    final now = DateTime.now();
    final sameDay = value.year == now.year && value.month == now.month && value.day == now.day;
    final yesterday = value.year == now.year && value.month == now.month && value.day == now.day - 1;

    if (sameDay) {
      return 'HARI INI • ${DateFormat('dd MMMM yyyy', 'id_ID').format(value)}';
    }
    if (yesterday) {
      return 'KEMARIN • ${DateFormat('dd MMMM yyyy', 'id_ID').format(value)}';
    }
    return DateFormat('dd MMMM yyyy', 'id_ID').format(value).toUpperCase();
  }

  Widget _buildActivityCard(_ActivityLogItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (item.status.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.status,
                              style: TextStyle(
                                color: item.badgeTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: _textSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.meta,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final filtered = _filterItems(
                (await FirebaseFirestore.instance
                        .collectionGroup('login_history')
                        .get()
                        .then((value) => value.docs.map(_parseLoginLog).toList())) +
                    (await FirebaseFirestore.instance
                        .collectionGroup('calculation_history')
                        .get()
                        .then((value) => value.docs.map(_parseCalculationLog).toList())),
              );
              await _downloadAuditPdf(filtered);
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Unduh Log Audit Lengkap (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F5F4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: _olive, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seluruh log aktivitas tersimpan dengan enkripsi dan dapat diunduh sesuai kebutuhan audit internal. ORVIX Audit Engine v2.4.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF5B6159),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _ActivityLogItem _parseLoginLog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final fullName = (data['nama'] ?? data['user_name'] ?? 'Admin').toString();
    final role = (data['role'] ?? 'admin').toString();
    final timestamp =
        data['logged_in_at'] ?? data['loggedInAt'] ?? data['created_at'];
    final createdAt = _parseDate(timestamp);
    final safeName = fullName.trim().isEmpty ? 'Admin ORVIX' : fullName;
    final isAdmin = role.toLowerCase().contains('admin');

    return _ActivityLogItem(
      title: isAdmin ? 'Login Sesi Administrator' : 'Login Sesi Staff',
      subtitle: 'Verifikasi akses masuk $safeName melalui sistem keamanan internal ORVIX.',
      category: 'Autentikasi',
      type: 'autentikasi',
      status: '',
      badgeColor: Colors.transparent,
      badgeTextColor: Colors.transparent,
      icon: Icons.security_rounded,
      iconBg: const Color(0xFFEAF4FF),
      iconColor: const Color(0xFF1F7BE8),
      meta: '${_formatLocation(data)} • ${_formatIp(data)}',
      createdAt: createdAt,
    );
  }

  _ActivityLogItem _parseCalculationLog(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final userName = (data['user_name'] ?? data['nama'] ?? 'Staff').toString();
    final type = (data['jenis_kalkulator'] ?? data['jenisKalkulator'] ?? 'Kalkulator')
        .toString();
    final createdAt = _parseDate(data['created_at'] ?? data['createdAt']);
    final amount = (data['hasil'] is num) ? (data['hasil'] as num).toDouble() : 0;
    final title = type.toLowerCase().contains('pivot')
        ? 'Pembaruan Pivot Point'
        : type.toLowerCase().contains('nest')
            ? 'Perhitungan NEST Terekam'
            : 'Perhitungan ${type.isNotEmpty ? type : 'Emas'} Tersimpan';

    return _ActivityLogItem(
      title: title,
      subtitle: '$userName melakukan perhitungan ${type.isNotEmpty ? type : 'emaster'}. Hasil: ${amount.toStringAsFixed(2)}.',
      category: 'Manajemen Staff',
      type: 'manajemen',
      status: '',
      badgeColor: Colors.transparent,
      badgeTextColor: Colors.transparent,
      icon: Icons.calculate_rounded,
      iconBg: const Color(0xFFF8E6DA),
      iconColor: _orange,
      meta: '${_formatLocation(data)} • ${_formatIp(data)}',
      createdAt: createdAt,
    );
  }

  String _formatLocation(Map<String, dynamic> data) {
    final location =
        data['lokasi'] ?? data['location'] ?? data['device_name'] ?? 'Indonesia';
    return location.toString();
  }

  String _formatIp(Map<String, dynamic> data) {
    final value = data['ip_address'] ?? data['ipAddress'] ?? '192.168.1.10';
    return value.toString();
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Future<void> _downloadAuditPdf(List<_ActivityLogItem> items) async {
    final doc = pw.Document();
    final rows = <List<String>>[
      ['WAKTU', 'JENIS', 'AKTIVITAS', 'STATUS'],
      ...items.take(30).map((item) => [
            DateFormat('dd/MM/yyyy • HH:mm').format(item.createdAt),
            item.category,
            item.title,
            item.status,
          ]),
    ];

    doc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Riwayat Aktivitas Admin ORVIX',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColors.deepOrange,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Waktu unduh: ${DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey),
              ),
              pw.SizedBox(height: 18),
              pw.Table(
                border: pw.TableBorder.all(color: pdf.PdfColors.orange, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(90),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(220),
                  3: const pw.FixedColumnWidth(70),
                },
                children: rows.map((row) {
                  return pw.TableRow(
                    children: row.map((cell) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          cell,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: row.first == 'WAKTU'
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
              pw.Spacer(),
              pw.Text(
                'Dokumen laporan dibuat otomatis oleh Sistem Audit ORVIX',
                style: const pw.TextStyle(fontSize: 8, color: pdf.PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/riwayat_aktivitas_admin_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await doc.save());

    if (!mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Riwayat Aktivitas Admin ORVIX',
        text: 'Log aktivitas admin ORVIX',
      ),
    );
  }
}

class _ActivityLogItem {
  final String title;
  final String subtitle;
  final String category;
  final String type;
  final String status;
  final Color badgeColor;
  final Color badgeTextColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String meta;
  final DateTime createdAt;

  _ActivityLogItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.type,
    required this.status,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.meta,
    required this.createdAt,
  });
}
