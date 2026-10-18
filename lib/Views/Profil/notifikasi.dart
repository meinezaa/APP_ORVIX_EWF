import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Models/historikalkulator_model.dart';
import '../../Models/notifikasi_model.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/history_service.dart';

class NotifikasiView extends StatefulWidget {
  const NotifikasiView({super.key});

  @override
  State<NotifikasiView> createState() => _NotifikasiViewState();
}

class _NotifikasiViewState extends State<NotifikasiView> {
  int _selectedFilter = 0;
  bool _isMarkingAllRead = false;

  final List<NotifikasiModel> _notifications = [
    NotifikasiModel(
      id: 'gold-price-updated',
      title: 'Harga emas diperbarui',
      message: 'Data harga emas terbaru sudah tersedia.',
      time: '07.45',
      icon: Icons.trending_up,
      isRead: false,
      group: 'Hari ini',
    ),
    NotifikasiModel(
      id: 'welcome-orvix',
      title: 'Selamat datang di ORVIX',
      message: 'Mulai gunakan kalkulator untuk membantu perhitungan Anda.',
      time: 'Kemarin',
      icon: Icons.waving_hand_outlined,
      isRead: false,
      group: 'Kemarin',
    ),
    NotifikasiModel(
      id: 'history-reminder',
      title: 'Jangan lupa cek histori',
      message: 'Lihat kembali seluruh aktivitas perhitungan Anda.',
      time: 'Kemarin',
      icon: Icons.history,
      isRead: false,
      group: 'Kemarin',
    ),
  ];

  Stream<Set<String>> _watchReadIds() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(<String>{});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_status')
        .where('is_read', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                final action = doc.data()['read_action'];
                return action == 'tap' || action == 'mark_all';
              })
              .map((doc) => doc.id)
              .toSet(),
        );
  }

  Future<void> _markAsRead(NotifikasiModel notification) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || notification.isRead) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_status')
        .doc(notification.id)
        .set({
          'is_read': true,
          'read_action': 'tap',
          'read_at': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HistoryModel>>(
      stream: HistoryService.watchHistory(),
      builder: (context, historySnapshot) => StreamBuilder<Set<String>>(
        stream: _watchReadIds(),
        builder: (context, statusSnapshot) {
          final readIds = statusSnapshot.data ?? <String>{};
          final notifications = [
            ..._notifications.map(
              (notification) => NotifikasiModel(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                time: notification.time,
                icon: notification.icon,
                isRead: readIds.contains(notification.id),
                group: _localizedGroup(context, notification.group),
              ),
            ),
            ..._buildCalculationNotifications(
              context,
              historySnapshot.data ?? const <HistoryModel>[],
              readIds,
            ),
          ];
          final visible = notifications
              .where(
                (item) =>
                    _selectedFilter == 0 ||
                    (_selectedFilter == 1 ? item.isRead : !item.isRead),
              )
              .toList();
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.pageGradient(context),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildFilter(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.background(context),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: visible.isEmpty
                            ? _buildEmptyState()
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  34,
                                  28,
                                  34,
                                  30,
                                ),
                                children: _buildGroupedNotifications(
                                  visible,
                                  notifications,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<NotifikasiModel> _buildCalculationNotifications(
    BuildContext context,
    List<HistoryModel> history,
    Set<String> readIds,
  ) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final uniqueHistory = <HistoryModel>[];
    for (final item in history) {
      final type = item.jenisKalkulator.toLowerCase();
      final isSupportedType =
          type.contains('pivot') ||
          type.contains('nest') ||
          (type.contains('emas') && type.contains('fisik'));
      if (!isSupportedType || uniqueHistory.any(item.isSameCalculationAs)) {
        continue;
      }
      uniqueHistory.add(item);
    }

    return uniqueHistory.map((item) {
      final type = item.jenisKalkulator.toLowerCase();
      final indication = (item.indikasi ?? '').toUpperCase();
      final isPivot = type.contains('pivot');
      final isNest = type.contains('nest');
      final idPrefix = isPivot
          ? 'pivot'
          : isNest
          ? 'nest'
          : 'physical';
      final id = '$idPrefix-${item.id}';
      final title = isPivot
          ? '${isEnglish ? 'Pivot Point Result' : 'Hasil Pivot Point'}: $indication'
          : isNest
          ? '${isEnglish ? 'NEST Result' : 'Hasil NEST'}: $indication'
          : isEnglish
          ? 'Physical Gold Calculation'
          : 'Perhitungan Emas Fisik';
      final message = isPivot
          ? isEnglish
                ? 'Your Pivot Point value is ${item.hasil.toStringAsFixed(2)}. Signal: $indication.'
                : 'Nilai Pivot Point Anda adalah ${item.hasil.toStringAsFixed(2)}. Indikasi: $indication.'
          : isNest
          ? isEnglish
                ? 'NEST result: ${item.hasil.toStringAsFixed(2)}. Open: ${item.open?.toStringAsFixed(2) ?? '-'}, Close: ${item.close?.toStringAsFixed(2) ?? '-'}. Signal: $indication.'
                : 'Hasil NEST ${item.hasil.toStringAsFixed(2)}. Open: ${item.open?.toStringAsFixed(2) ?? '-'}, Close: ${item.close?.toStringAsFixed(2) ?? '-'}. Indikasi: $indication.'
          : isEnglish
          ? 'Physical Gold calculation result: ${item.hasil.toStringAsFixed(2)}.'
          : 'Hasil perhitungan Emas Fisik adalah ${item.hasil.toStringAsFixed(2)}.';
      return NotifikasiModel(
        id: id,
        title: title,
        message: message,
        time: _formatTime(item.createdAt),
        icon: isPivot || isNest
            ? indication == 'BUY'
                  ? Icons.trending_up
                  : Icons.trending_down
            : Icons.check_circle_outline,
        isRead: readIds.contains(id),
        group: _isToday(item.createdAt)
            ? (isEnglish ? 'Today' : 'Hari ini')
            : (isEnglish ? 'Yesterday' : 'Kemarin'),
      );
    }).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';

  String _localizedGroup(BuildContext context, String group) =>
      AppStrings.text(context, group);

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        _circleButton(Icons.arrow_back, () => Navigator.pop(context)),
        const SizedBox(width: 12),
        Text(
          AppStrings.text(context, 'Notifikasi'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: const Color(0xFFE07856), size: 24),
      ),
    ),
  );

  Widget _buildFilter() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 26),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        _filterButton(AppStrings.text(context, 'Semua'), 0),
        _filterButton(AppStrings.text(context, 'Sudah dibaca'), 1),
        _filterButton(AppStrings.text(context, 'Belum dibaca'), 2),
      ],
    ),
  );

  Widget _buildMarkAllReadButton(List<NotifikasiModel> notifications) =>
      TextButton.icon(
        onPressed: _isMarkingAllRead
            ? null
            : () => _markAllAsRead(notifications),
        icon: const Icon(Icons.mark_email_read_outlined, size: 18),
        label: Text(AppStrings.text(context, 'Baca semua')),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFD95D16),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );

  Future<void> _markAllAsRead(List<NotifikasiModel> notifications) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isMarkingAllRead) return;
    final unread = notifications.where((notification) => !notification.isRead);
    if (unread.isEmpty) return;

    setState(() => _isMarkingAllRead = true);
    try {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notification_status');
      final items = unread.toList();
      for (var start = 0; start < items.length; start += 450) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (start + 450).clamp(0, items.length);
        for (final notification in items.sublist(start, end)) {
          batch.set(collection.doc(notification.id), {
            'is_read': true,
            'read_action': 'mark_all',
            'read_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.text(context, 'Notifikasi gagal ditandai dibaca.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Widget _filterButton(String label, int index) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _selectedFilter == index
              ? const Color(0xFFD95D16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _selectedFilter == index
                ? Colors.white
                : const Color(0xFFD95D16),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );

  List<Widget> _buildGroupedNotifications(
    List<NotifikasiModel> items,
    List<NotifikasiModel> allNotifications,
  ) {
    final widgets = <Widget>[];
    final canMarkAll =
        (_selectedFilter == 0 || _selectedFilter == 2) &&
        allNotifications.any((item) => !item.isRead);
    var markAllButtonAdded = false;
    for (final group in [
      AppStrings.text(context, 'Hari ini'),
      AppStrings.text(context, 'Kemarin'),
    ]) {
      final groupItems = items.where((item) => item.group == group).toList();
      if (groupItems.isEmpty) continue;
      widgets.add(
        Row(
          children: [
            Text(
              group,
              style: TextStyle(
                color: Color(0xFFD95D16),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (canMarkAll && !markAllButtonAdded)
              _buildMarkAllReadButton(allNotifications),
          ],
        ),
      );
      if (canMarkAll && !markAllButtonAdded) {
        markAllButtonAdded = true;
      }
      widgets.add(const SizedBox(height: 10));
      for (final item in groupItems) {
        widgets.add(_notificationCard(item));
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _notificationCard(NotifikasiModel notification) => GestureDetector(
    onTap: () => _markAsRead(notification),
    child: Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppTheme.surface(context)
            : AppTheme.surfaceRaised(context),
        border: Border.all(
          color: AppTheme.border(context),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notification.icon, color: const Color(0xFFE87520), size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.text(context, notification.title),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: notification.isRead
                        ? FontWeight.w600
                        : FontWeight.w800,
                    color: AppTheme.text(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.text(context, notification.message),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            notification.time,
            style: TextStyle(fontSize: 10, color: AppTheme.mutedText(context)),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Text(
      AppStrings.text(context, 'Belum ada notifikasi'),
      style: TextStyle(
        color: AppTheme.mutedText(context),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
