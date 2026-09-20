import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotifikasiAdminView extends StatefulWidget {
  const NotifikasiAdminView({super.key});

  @override
  State<NotifikasiAdminView> createState() => _NotifikasiAdminViewState();
}

class _AdminNotification {
  const _AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.icon,
    required this.color,
    required this.category,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String category;
  final bool isRead;
}

class _NotifikasiAdminViewState extends State<NotifikasiAdminView> {
  static const _orange = Color(0xFFD97745);
  static const _background = Color(0xFFFFF8F3);
  int _selectedFilter = 0;

  Stream<Set<String>> _readIdsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(<String>{});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_status')
        .where('is_read', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  DateTime _dateValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _statusId(String type, DocumentSnapshot<Map<String, dynamic>> doc) =>
      '$type-${doc.reference.path.replaceAll('/', '_')}';

  List<_AdminNotification> _buildNotifications(
    QuerySnapshot<Map<String, dynamic>> calculations,
    QuerySnapshot<Map<String, dynamic>> logins,
    Set<String> readIds,
  ) {
    final notifications = <_AdminNotification>[];
    for (final doc in calculations.docs) {
      final data = doc.data();
      final date = _dateValue(data, ['created_at', 'createdAt']);
      final name =
          (data['user_name'] ?? data['nama'] ?? data['name'] ?? 'Staff')
              .toString()
              .trim();
      final type =
          (data['jenis_kalkulator'] ?? data['jenisKalkulator'] ?? 'Perhitungan')
              .toString();
      final id = _statusId('calculation', doc);
      notifications.add(
        _AdminNotification(
          id: id,
          title: 'Perhitungan $type',
          message: '$name melakukan perhitungan baru.',
          date: date,
          icon: Icons.calculate_outlined,
          color: const Color(0xFFFFE8DC),
          category: 'Perhitungan',
          isRead: readIds.contains(id),
        ),
      );
    }
    for (final doc in logins.docs) {
      final data = doc.data();
      final date = _dateValue(data, ['logged_in_at', 'loggedInAt']);
      if (date.millisecondsSinceEpoch == 0) continue;
      final name = (data['nama'] ?? data['name'] ?? 'Staff').toString().trim();
      final device = (data['device'] ?? data['device_name'] ?? '')
          .toString()
          .trim();
      final id = _statusId('login', doc);
      notifications.add(
        _AdminNotification(
          id: id,
          title: 'Login perangkat baru',
          message: device.isEmpty
              ? '$name masuk ke sistem.'
              : '$name masuk melalui $device.',
          date: date,
          icon: Icons.login_outlined,
          color: const Color(0xFFFFD5D5),
          category: 'Keamanan',
          isRead: readIds.contains(id),
        ),
      );
    }
    notifications.sort((a, b) => b.date.compareTo(a.date));
    return notifications;
  }

  Future<void> _markRead(_AdminNotification notification) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || notification.isRead) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_status')
        .doc(notification.id)
        .set({'is_read': true, 'read_at': FieldValue.serverTimestamp()});
  }

  Future<void> _markAllRead(List<_AdminNotification> notifications) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notification_status');
    for (final notification in notifications.where((item) => !item.isRead)) {
      batch.set(collection.doc(notification.id), {
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, calculationSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collectionGroup('login_history')
              .snapshots(),
          builder: (context, loginSnapshot) {
            return StreamBuilder<Set<String>>(
              stream: _readIdsStream(),
              builder: (context, readSnapshot) {
                final notifications = _buildNotifications(
                  calculationSnapshot.data ??
                      const _EmptyQuerySnapshot<Map<String, dynamic>>(),
                  loginSnapshot.data ??
                      const _EmptyQuerySnapshot<Map<String, dynamic>>(),
                  readSnapshot.data ?? <String>{},
                );
                final visible = notifications.where((notification) {
                  if (_selectedFilter == 1) {
                    return notification.category == 'Perhitungan';
                  }
                  if (_selectedFilter == 2) {
                    return notification.category == 'Keamanan';
                  }
                  if (_selectedFilter == 3) return !notification.isRead;
                  return true;
                }).toList();
                return _buildPage(notifications, visible);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    List<_AdminNotification> all,
    List<_AdminNotification> visible,
  ) {
    final unread = all.where((notification) => !notification.isRead).length;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(unread, all),
            _buildFilter(unread),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('Belum ada notifikasi'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      itemCount: visible.length,
                      itemBuilder: (context, index) =>
                          _notificationCard(visible[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int unread, List<_AdminNotification> all) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Notifikasi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: unread == 0 ? null : () => _markAllRead(all),
            child: const Text('Tandai Dibaca'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(int unread) {
    const labels = ['Semua', 'Perhitungan', 'Keamanan', 'Belum dibaca'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Row(
            children: [
              const Text(
                'Pusat Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              if (unread > 0) _countBadge(unread),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: labels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ChoiceChip(
              label: Text(labels[index]),
              selected: _selectedFilter == index,
              onSelected: (_) => setState(() => _selectedFilter = index),
              selectedColor: _orange,
              labelStyle: TextStyle(
                color: _selectedFilter == index ? Colors.white : _orange,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.white,
              side: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _countBadge(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE8DC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$count Baru',
      style: const TextStyle(
        color: _orange,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _notificationCard(_AdminNotification notification) {
    return GestureDetector(
      onTap: () => _markRead(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFFF7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFF0E3DC)
                : const Color(0xFFFFDCCB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.icon, color: _orange),
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
                          notification.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.date),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F625B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _categoryBadge(notification.category),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 7, color: _orange),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EA),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, color: Color(0xFF755F55)),
    ),
  );

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _EmptyQuerySnapshot<T> implements QuerySnapshot<T> {
  const _EmptyQuerySnapshot();

  @override
  List<QueryDocumentSnapshot<T>> get docs => const [];

  @override
  List<DocumentChange<T>> get docChanges => const [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => 0;
}
