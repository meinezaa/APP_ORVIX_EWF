import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NestDetailScreen extends StatelessWidget {
  const NestDetailScreen({super.key});

  DateTime? _date(Map<String, dynamic> data) {
    final value = data['created_at'] ?? data['createdAt'];
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    return null;
  }

  String _text(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  double _number(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }

  String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  String? _validPhotoUrl(Object? value) {
    final url = value?.toString().trim();
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? url
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('calculation_history')
          .snapshots(),
      builder: (context, snapshot) {
        final docs =
            (snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where(
                  (doc) =>
                      _text(doc.data(), [
                        'jenis_kalkulator',
                        'jenisKalkulator',
                      ], '').toLowerCase() ==
                      'nest',
                )
                .toList()
              ..sort(
                (a, b) => (_date(b.data()) ?? DateTime(1970)).compareTo(
                  _date(a.data()) ?? DateTime(1970),
                ),
              );

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F2),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context),
                  const SizedBox(height: 20),
                  _summary(docs),
                  const SizedBox(height: 24),
                  Text(
                    'Daftar Staff Perhitungan NEST (${docs.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty) _emptyState() else ...docs.map(_staffCard),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left),
          ),
        ),
      ),
      const Column(
        children: [
          Text(
            'PERHITUNGAN ORVIX',
            style: TextStyle(
              color: Color(0xFFEE6C3A),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            'Daftar NEST',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ],
  );

  Widget _summary(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEE6C3A), Color(0xFFF39256)],
        ),
      ),
      child: Row(
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
        ],
      ),
    );
  }

  Widget _staffCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = _text(data, ['user_name', 'nama', 'name'], 'Staff');
    final role = _text(data, ['role'], 'Staff');
    final action = _text(data, ['indikasi', 'action'], '-').toUpperCase();
    final date = _date(data);
    final initials = _initials(name).isEmpty ? 'S' : _initials(name);
    final userId = _text(data, ['user_id', 'userId'], '');
    final savedPhoto = _validPhotoUrl(
      data['foto_profil_path'] ?? data['photoUrl'],
    );

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
              _profileAvatar(userId, savedPhoto, initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(role, style: const TextStyle(color: Colors.black45)),
                  ],
                ),
              ),
              Text(
                date == null ? '-' : DateFormat('HH:mm').format(date),
                style: const TextStyle(color: Colors.black45),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEST: ${NumberFormat('#,##0.00').format(_number(data, 'hasil'))}',
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

  Widget _profileAvatar(String userId, String? savedPhoto, String initials) {
    if (savedPhoto != null || userId.isEmpty) {
      return _avatarContent(savedPhoto, initials);
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        final photo = _validPhotoUrl(
          userData?['foto_profil_path'] ?? userData?['photoUrl'],
        );
        return _avatarContent(photo, initials);
      },
    );
  }

  Widget _avatarContent(String? photoUrl, String initials) {
    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        shape: BoxShape.circle,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _emptyState() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text('Belum ada staff yang melakukan perhitungan NEST.'),
  );
}
