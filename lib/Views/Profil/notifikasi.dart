import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Models/histori_model.dart';
import '../../Models/notifikasi_model.dart';
import '../../Services/history_service.dart';

class NotifikasiView extends StatefulWidget {
  const NotifikasiView({super.key});

  @override
  State<NotifikasiView> createState() => _NotifikasiViewState();
}

class _NotifikasiViewState extends State<NotifikasiView> {
  int _selectedFilter = 0;

  final List<NotifikasiModel> _notifications = [
    NotifikasiModel(id: 'calculation-saved', title: 'Perhitungan tersimpan', message: 'Hasil perhitungan Emas Fisik berhasil disimpan.', time: '08.30', icon: Icons.check_circle_outline, isRead: false, group: 'Hari ini'),
    NotifikasiModel(id: 'gold-price-updated', title: 'Harga emas diperbarui', message: 'Data harga emas terbaru sudah tersedia.', time: '07.45', icon: Icons.trending_up, isRead: false, group: 'Hari ini'),
    NotifikasiModel(id: 'welcome-orvix', title: 'Selamat datang di ORVIX', message: 'Mulai gunakan kalkulator untuk membantu perhitungan Anda.', time: 'Kemarin', icon: Icons.waving_hand_outlined, isRead: true, group: 'Kemarin'),
    NotifikasiModel(id: 'saved-pivot-example', title: 'Perhitungan tersimpan', message: 'Hasil perhitungan Pivot Point berhasil disimpan.', time: 'Kemarin', icon: Icons.check_circle_outline, isRead: true, group: 'Kemarin'),
    NotifikasiModel(id: 'history-reminder', title: 'Jangan lupa cek histori', message: 'Lihat kembali seluruh aktivitas perhitungan Anda.', time: 'Kemarin', icon: Icons.history, isRead: true, group: 'Kemarin'),
  ];

  Stream<Set<String>> _watchReadIds() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(<String>{});
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notification_status').where('is_read', isEqualTo: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> _markAsRead(NotifikasiModel notification) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || notification.isRead) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notification_status').doc(notification.id).set({'is_read': true, 'read_at': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HistoryModel>>(
      stream: HistoryService.watchHistory(),
      builder: (context, historySnapshot) => StreamBuilder<Set<String>>(
        stream: _watchReadIds(),
        builder: (context, statusSnapshot) {
          final readIds = statusSnapshot.data ?? <String>{};
          final notifications = [..._notifications, ..._buildPivotNotifications(historySnapshot.data ?? const <HistoryModel>[], readIds)];
          final visible = notifications.where((item) => _selectedFilter == 0 || (_selectedFilter == 1 ? item.isRead : !item.isRead)).toList();
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9854D), Color(0xFFF8C7A8), Color(0xFFFFF8F3)], stops: [0.0, 0.36, 0.86])),
              child: SafeArea(
                child: Column(children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildFilter(),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Color(0xFFFFFDFC), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                      child: visible.isEmpty ? _buildEmptyState() : ListView(padding: const EdgeInsets.fromLTRB(34, 28, 34, 30), children: _buildGroupedNotifications(visible)),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  List<NotifikasiModel> _buildPivotNotifications(List<HistoryModel> history, Set<String> readIds) => history.where((item) => item.jenisKalkulator.toLowerCase().contains('pivot')).map((item) {
        final indication = (item.indikasi ?? '').toUpperCase();
        final id = 'pivot-${item.id}';
        return NotifikasiModel(id: id, title: 'Hasil Pivot Point: $indication', message: 'Nilai Pivot Point Anda adalah ${item.hasil.toStringAsFixed(2)}. Indikasi: $indication.', time: _formatTime(item.createdAt), icon: indication == 'BUY' ? Icons.trending_up : Icons.trending_down, isRead: readIds.contains(id), group: _isToday(item.createdAt) ? 'Hari ini' : 'Kemarin');
      }).toList();

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatTime(DateTime date) => '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';

  Widget _buildHeader() => Padding(padding: const EdgeInsets.symmetric(horizontal: 26), child: Row(children: [_circleButton(Icons.arrow_back, () => Navigator.pop(context)), const SizedBox(width: 16), const Text('Notifikasi', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700))]));

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(color: Colors.white, shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 40, height: 40, child: Icon(icon, color: const Color(0xFF332923), size: 24))));

  Widget _buildFilter() => Container(margin: const EdgeInsets.symmetric(horizontal: 26), padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Row(children: [_filterButton('Semua', 0), _filterButton('Sudah dibaca', 1), _filterButton('Belum dibaca', 2)]));

  Widget _filterButton(String label, int index) => Expanded(child: GestureDetector(onTap: () => setState(() => _selectedFilter = index), child: AnimatedContainer(duration: const Duration(milliseconds: 180), height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: _selectedFilter == index ? const Color(0xFFD95D16) : Colors.transparent, borderRadius: BorderRadius.circular(22)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: _selectedFilter == index ? Colors.white : const Color(0xFFD95D16), fontSize: 13, fontWeight: FontWeight.w500)))));

  List<Widget> _buildGroupedNotifications(List<NotifikasiModel> items) {
    final widgets = <Widget>[];
    for (final group in ['Hari ini', 'Kemarin']) {
      final groupItems = items.where((item) => item.group == group).toList();
      if (groupItems.isEmpty) continue;
      widgets.add(Text(group, style: const TextStyle(color: Color(0xFFD95D16), fontSize: 14, fontWeight: FontWeight.w700)));
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
            color: notification.isRead ? const Color(0xFFF8F8F8) : const Color(0xFFFFE9DB),
            border: Border.all(color: notification.isRead ? const Color(0xFFD1D1D1) : const Color(0xFFF1B487)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
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
                    Text(notification.title, style: TextStyle(fontSize: 13, fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800, color: const Color(0xFF302622))),
                    const SizedBox(height: 4),
                    Text(notification.message, style: const TextStyle(fontSize: 11, color: Color(0xFF756B66), height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(notification.time, style: const TextStyle(fontSize: 10, color: Color(0xFF8B7D75))),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => const Center(child: Text('Belum ada notifikasi', style: TextStyle(color: Color(0xFF766D68), fontSize: 14, fontWeight: FontWeight.w600)));
}
