import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManajemenNotifikasiAdminView extends StatefulWidget {
  const ManajemenNotifikasiAdminView({super.key});

  @override
  State<ManajemenNotifikasiAdminView> createState() =>
      _ManajemenNotifikasiAdminViewState();
}

class _ManajemenNotifikasiAdminViewState
    extends State<ManajemenNotifikasiAdminView> {
  static const _orange = Color(0xFFB85C2B);
  static const _softOrange = Color(0xFFFFE9DC);
  static const _background = Color(0xFFFFF9F5);

  final Map<String, bool> _defaults = {
    'calculation_alerts': true,
    'large_transaction_alerts': true,
    'daily_recap': false,
    'login_alerts': true,
    'credential_alerts': true,
    'staff_status_alerts': true,
    'push_enabled': true,
    'email_enabled': true,
  };
  bool _isSaving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _preferencesRef {
    final user = _user;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('notification_preferences');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _preferencesStream() =>
      _preferencesRef?.snapshots();

  Future<void> _setPreference(String key, bool value) async {
    final ref = _preferencesRef;
    if (ref == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.set({
        key: value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _value(Map<String, dynamic> data, String key) =>
      data[key] is bool ? data[key] as bool : _defaults[key] ?? false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _preferencesStream(),
      builder: (context, preferencesSnapshot) {
        final preferences = preferencesSnapshot.data?.data() ?? const {};
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _user == null
              ? null
              : FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .snapshots(),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data?.data() ?? const {};
            final email = (profile['email'] ?? _user?.email ?? '-').toString();
            final device =
                (profile['active_device'] ??
                        profile['device'] ??
                        'Perangkat utama')
                    .toString();
            return Scaffold(
              backgroundColor: _background,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                        children: [
                          _buildIntro(),
                          const SizedBox(height: 14),
                          _buildSummary(preferences),
                          const SizedBox(height: 22),
                          _sectionTitle(
                            'ALERT PERHITUNGAN & TRANSAKSI',
                            'Real-time',
                          ),
                          _buildSettingGroup([
                            _setting(
                              icon: Icons.calculate_outlined,
                              title: 'Kalkulasi Staff Selesai',
                              description:
                                  'Push alert saat staff menyelesaikan kalkulasi.',
                              keyName: 'calculation_alerts',
                              data: preferences,
                            ),
                            _setting(
                              icon: Icons.shield_outlined,
                              title: 'Ambang Transaksi Besar',
                              description:
                                  'Peringatan ketika transaksi melewati batas normal.',
                              keyName: 'large_transaction_alerts',
                              data: preferences,
                              badge: 'PRIORITAS',
                            ),
                            _setting(
                              icon: Icons.receipt_long_outlined,
                              title: 'Rekapitulasi Harian',
                              description:
                                  'Ringkasan volume dan aktivitas setiap penutupan hari.',
                              keyName: 'daily_recap',
                              data: preferences,
                            ),
                          ]),
                          const SizedBox(height: 22),
                          _sectionTitle(
                            'KEAMANAN & AKUN ADMIN',
                            'Sistem Proteksi',
                          ),
                          _buildSettingGroup([
                            _setting(
                              icon: Icons.devices_outlined,
                              title: 'Login Sesi & Perangkat Baru',
                              description:
                                  'Alert saat ada login dari perangkat baru.',
                              keyName: 'login_alerts',
                              data: preferences,
                              badge: 'WAJIB',
                            ),
                            _setting(
                              icon: Icons.password_outlined,
                              title: 'Perubahan Kredensial & PIN',
                              description:
                                  'Konfirmasi saat kredensial admin berubah.',
                              keyName: 'credential_alerts',
                              data: preferences,
                            ),
                            _setting(
                              icon: Icons.manage_accounts_outlined,
                              title: 'Status Akun Staff Lapangan',
                              description:
                                  'Pemberitahuan status akun staff berubah.',
                              keyName: 'staff_status_alerts',
                              data: preferences,
                            ),
                          ]),
                          const SizedBox(height: 22),
                          _sectionTitle('SALURAN PENGIRIMAN ALERT', ''),
                          _buildChannelGroup(email, device, preferences),
                          const SizedBox(height: 20),
                          if (_isSaving)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text('Menyimpan perubahan...'),
                              ),
                            ),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFF2E4DD))),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const Expanded(
          child: Text(
            'Manajemen Notifikasi',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _buildIntro() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _softOrange,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan Alert ORVIX',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Konfigurasi notifikasi push dan email untuk memantau aktivitas sistem secara real-time.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF745F55),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildSummary(Map<String, dynamic> data) => Row(
    children: [
      Expanded(
        child: _summaryCard(
          'STATUS FILTER',
          '${_defaults.length - data.values.where((value) => value == false).length} Aktif',
          Icons.tune_outlined,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _summaryCard(
          'KANAL UTAMA',
          _value(data, 'push_enabled') && _value(data, 'email_enabled')
              ? 'Push & Email'
              : _value(data, 'push_enabled')
              ? 'Push'
              : 'Email',
          Icons.mark_email_unread_outlined,
        ),
      ),
    ],
  );

  Widget _summaryCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _softOrange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _orange, size: 19),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String badge) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF786960),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (badge.isNotEmpty) _badge(badge),
      ],
    ),
  );

  Widget _buildSettingGroup(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(children: children),
  );

  Widget _setting({
    required IconData icon,
    required String title,
    required String description,
    required String keyName,
    required Map<String, dynamic> data,
    String? badge,
  }) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _softOrange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _orange, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (badge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: _badge(badge),
                ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF766860),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _value(data, keyName),
          activeThumbColor: _orange,
          onChanged: (value) => _setPreference(keyName, value),
        ),
      ],
    ),
  );

  Widget _buildChannelGroup(
    String email,
    String device,
    Map<String, dynamic> data,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        _channelTile(
          Icons.phone_android_outlined,
          'Push Notifikasi Aplikasi',
          device,
          _value(data, 'push_enabled'),
          'push_enabled',
        ),
        const SizedBox(height: 9),
        _channelTile(
          Icons.mail_outline,
          'Email Resmi Administrator',
          email,
          _value(data, 'email_enabled'),
          'email_enabled',
        ),
      ],
    ),
  );

  Widget _channelTile(
    IconData icon,
    String title,
    String subtitle,
    bool enabled,
    String keyName,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: enabled ? _softOrange : const Color(0xFFF5F1EF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled ? _orange : const Color(0xFFD5C9C3),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF786960)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: enabled,
          activeThumbColor: _orange,
          onChanged: (value) => _setPreference(keyName, value),
        ),
      ],
    ),
  );

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: _softOrange,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        color: _orange,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _isSaving
          ? null
          : () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preferensi alert tersimpan secara real-time.'),
              ),
            ),
      icon: const Icon(Icons.save_outlined),
      label: const Text('Simpan Preferensi Alert'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
