import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoginDetailScreen extends StatelessWidget {
  const LoginDetailScreen({super.key, this.loginData});

  final Map<String, dynamic>? loginData;

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
    final value = _value(data, ['logged_in_at', 'loggedInAt', 'timestamp']);
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    return null;
  }

  String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final displayData = loginData ?? const <String, dynamic>{};
    final raw =
        (displayData['rawData'] as Map?)?.cast<String, dynamic>() ??
        displayData;
    final name = _text(raw, ['nama', 'name', 'user_name'], 'Pengguna');
    final role = _text(raw, ['role'], 'Staff');
    final date = _date(raw) ?? displayData['timestamp'] as DateTime?;
    final email = _text(raw, ['email'], 'Tidak tersedia');
    final device = _text(raw, [
      'device',
      'device_name',
      'perangkat',
    ], 'Tidak tersedia');
    final browser = _text(raw, [
      'browser',
      'client',
      'platform',
    ], 'Tidak tersedia');
    final ip = _text(raw, ['ip_address', 'ip', 'alamat_ip'], 'Tidak tersedia');
    final verification = _text(raw, [
      'verification_method',
      'metode_verifikasi',
      'method',
    ], 'Email / Password');
    final duration = date == null
        ? 'Tidak tersedia'
        : _duration(date, DateTime.now());

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
              _userCard(name, role, date, duration),
              const SizedBox(height: 16),
              _infoCard('INFORMASI SESI LOGIN', [
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Tanggal Akses',
                  date == null
                      ? 'Tidak tersedia'
                      : DateFormat('d MMMM yyyy', 'id_ID').format(date),
                ),
                _infoRow(
                  Icons.shield_outlined,
                  'Metode Verifikasi',
                  verification,
                ),
                _infoRow(Icons.email_outlined, 'Email', email),
              ]),
              const SizedBox(height: 16),
              _infoCard('PERANGKAT & KEAMANAN JARINGAN', [
                _infoRow(Icons.smartphone_outlined, 'Perangkat', device),
                _infoRow(Icons.language_outlined, 'Browser / Klien', browser),
                _infoRow(Icons.location_on_outlined, 'Alamat IP', ip),
              ]),
              const SizedBox(height: 16),
              _activityCard(date),
            ],
          ),
        ),
      ),
    );
  }

  String _duration(DateTime start, DateTime end) {
    final difference = end.difference(start);
    if (difference.isNegative) return 'Belum dimulai';
    if (difference.inDays > 0) return '${difference.inDays} Hari Berjalan';
    if (difference.inHours > 0) return '${difference.inHours} Jam Berjalan';
    return '${difference.inMinutes} Menit Berjalan';
  }

  Widget _header(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.chevron_left),
      ),
      const Expanded(
        child: Column(
          children: [
            Text(
              'AKTIVITAS ORVIX',
              style: TextStyle(
                color: Color(0xFFEE6C3A),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Detail Sesi Login',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      const SizedBox(width: 48),
    ],
  );

  Widget _userCard(String name, String role, DateTime? date, String duration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFDE8E0),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(role, style: const TextStyle(color: Colors.black45)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'WAKTU AUTENTIKASI',
                  date == null
                      ? 'Tidak tersedia'
                      : DateFormat('HH:mm:ss').format(date),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _metric('DURASI TERHUBUNG', duration)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEE6C3A),
          ),
        ),
      ],
    ),
  );

  Widget _infoCard(String title, List<Widget> rows) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFEE6C3A)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  Widget _activityCard(DateTime? date) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AKTIVITAS DALAM SESI INI',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 14),
        _activity(
          'Berhasil Autentikasi Login',
          date == null
              ? 'Waktu login tidak tersedia'
              : DateFormat('HH:mm WIB').format(date),
        ),
      ],
    ),
  );

  Widget _activity(String title, String time) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.circle, size: 10, color: Color(0xFFEE6C3A)),
      const SizedBox(width: 12),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              time,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}
