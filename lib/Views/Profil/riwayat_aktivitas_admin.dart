import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiwayatAktivitasAdminPage extends StatefulWidget {
  const RiwayatAktivitasAdminPage({super.key});

  @override
  State<RiwayatAktivitasAdminPage> createState() =>
      _RiwayatAktivitasAdminPageState();
}

class _RiwayatAktivitasAdminPageState extends State<RiwayatAktivitasAdminPage> {
  String _searchText = '';
  DateTime? _selectedDate;
  final String _selectedFilter = 'Autentikasi';

  final Color _bgSoft = const Color(0xFFF4F1EE);
  final Color _orange = const Color(0xFFE68A4D);
  final Color _orangeDeep = const Color(0xFFCF6F2E);
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
            final loginItems = _dedupeLoginByBrand(
              (loginSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  .map(_parseLoginLog)
                  .toList(),
            );

            final allItems = loginItems
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
                          child: _buildDateSearchDropdown(allItems),
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
        ),
      ),
    );
  }

  List<_ActivityLogItem> _filterItems(List<_ActivityLogItem> items) {
    final query = _searchText.trim().toLowerCase();
    return items.where((item) {
      final categoryName = (item.category).toLowerCase();
      final typeName = (item.type).toLowerCase();
      final dateMatch = _selectedDate == null ||
          _isSameDate(item.createdAt, _selectedDate!);

      final typeMatch = _selectedFilter.toLowerCase() == 'autentikasi'
          ? categoryName == 'autentikasi' ||
              typeName == 'autentikasi' ||
              item.title.toLowerCase().contains('login sesi')
          : true;

      final queryMatch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.meta.toLowerCase().contains(query);

      return dateMatch && typeMatch && queryMatch;
    }).toList();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isHealthyStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('aman') ||
        normalized.contains('selesai') ||
        normalized.contains('tersimpan') ||
        normalized.contains('valid');
  }

  List<_ActivityLogItem> _dedupeLoginByBrand(List<_ActivityLogItem> items) {
    final latestByBrand = <String, _ActivityLogItem>{};

    for (final item in items) {
      final key = item.meta.trim().toLowerCase();
      final current = latestByBrand[key];
      if (current == null || item.createdAt.isAfter(current.createdAt)) {
        latestByBrand[key] = item;
      }
    }

    final deduped = latestByBrand.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return deduped;
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

  Future<void> _showDateSearchDialog(List<DateTime> dates) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = controller.text.trim().toLowerCase();
            final filteredDates = dates.where((date) {
              final label = DateFormat('dd MMM yyyy', 'id_ID').format(date).toLowerCase();
              return query.isEmpty || label.contains(query);
            }).toList();

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 460),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cari Tanggal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Masukkan tanggal...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: filteredDates.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text('Tanggal tidak ditemukan'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredDates.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final date = filteredDates[index];
                                  final label = DateFormat('dd MMM yyyy', 'id_ID').format(date);
                                  final isSelected = _selectedDate != null &&
                                      _isSameDate(date, _selectedDate!);

                                  return ListTile(
                                    title: Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected ? _orange : _textDark,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE68A4D)) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = date;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSearchDropdown(List<_ActivityLogItem> items) {
    final dates = items
        .map((item) => DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final label = _selectedDate == null
        ? 'Pilih Tanggal'
        : DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!);

    return GestureDetector(
      onTap: () => _showDateSearchDialog(dates),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF7B7B7B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _selectedDate == null ? _textSoft : _textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B7B7B)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _orange),
        ),
        child: Text(
          'Autentikasi',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
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
    final timeText = DateFormat('HH:mm', 'id_ID').format(item.createdAt);

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
                      '${item.subtitle} Jam login: $timeText.',
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
                  '${item.meta} • $timeText',
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
    final brand = _detectDeviceBrand(data);

    final timeLabel = DateFormat('HH:mm', 'id_ID').format(createdAt);

    return _ActivityLogItem(
      title: isAdmin ? 'Login Sesi Administrator' : 'Login Sesi Staff',
      subtitle: 'Verifikasi akses masuk ${brand.isNotEmpty ? brand : safeName} melalui sistem keamanan internal ORVIX.',
      category: 'Autentikasi',
      type: 'autentikasi',
      status: '',
      badgeColor: Colors.transparent,
      badgeTextColor: Colors.transparent,
      icon: Icons.security_rounded,
      iconBg: const Color(0xFFEAF4FF),
      iconColor: const Color(0xFF1F7BE8),
      meta: brand.isNotEmpty ? '$brand • $timeLabel' : 'Perangkat • $timeLabel',
      createdAt: createdAt,
    );
  }

  String _detectDeviceBrand(Map<String, dynamic> data) {
    final candidates = [
      data['device_name'],
      data['deviceName'],
      data['manufacturer'],
      data['manufacturer_name'],
      data['device_brand'],
      data['deviceBrand'],
      data['model'],
      data['phone_model'],
      data['device_model'],
      data['deviceModel'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isEmpty) continue;

      final cleaned = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
      if (cleaned.isEmpty) continue;

      final brand = cleaned.split(RegExp(r'\s+')).first;
      if (brand.isNotEmpty) return brand;
    }

    final fallBack = data['os'] ?? data['platform'] ?? '';
    if (fallBack is String && fallBack.trim().isNotEmpty) {
      return fallBack.trim();
    }

    return '';
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
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
