import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Home/beranda_admin.dart';
import '../Auth/login.dart';
import '../../Services/auth_services.dart';
import '../Analitik/analisis_perhitungan.dart';
import 'edit_profil_admin.dart';
import 'ganti_password_admin.dart';
import 'perangkat_terhubung_admin.dart';
import 'notifikasi_admin.dart';
import 'manajemen_notifikasi_admin.dart';
import 'riwayat_aktivitas_admin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ORVIX Admin Profile',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F6F2),
        fontFamily: 'Sans-Serif',
      ),
      home: const AdminProfileScreen(),
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  int _selectedNavIndex = 2; // Default ke tab Profil (index 2)
  String _adminName = 'Admin ORVIX';
  String _adminEmail = '-';
  String _adminPhoto = '';
  String _activeDeviceName = 'Perangkat utama';
  DateTime? _joinedDate;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();
      final data = userSnapshot.data() ?? <String, dynamic>{};
      final loginSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .collection('login_history')
          .orderBy('logged_in_at')
          .limit(1)
          .get();
      final rawCreated = data['createdAt'] ?? data['created_at'];
      final createdDate = rawCreated is Timestamp
          ? rawCreated.toDate().toLocal()
          : DateTime.tryParse('$rawCreated');
      final rawLogin = loginSnapshot.docs.isEmpty
          ? null
          : (loginSnapshot.docs.first.data()['logged_in_at'] ??
                loginSnapshot.docs.first.data()['loggedInAt']);
      final firstLogin = rawLogin is Timestamp
          ? rawLogin.toDate().toLocal()
          : DateTime.tryParse('$rawLogin');
      final preferences = await SharedPreferences.getInstance();
      final activeSessionId = preferences.getString(
        'active_login_session_${authUser.uid}',
      );
      final deviceIdentity = await _currentDeviceIdentity();
      Map<String, dynamic>? activeSession;
      if (activeSessionId != null && activeSessionId.isNotEmpty) {
        final activeSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .collection('login_history')
            .doc(activeSessionId)
            .get();
        activeSession = activeSnapshot.data();
      }
      if (!_matchesDevice(activeSession, deviceIdentity)) {
        final latestLoginSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .collection('login_history')
            .orderBy('logged_in_at', descending: true)
            .limit(1)
            .get();
        for (final doc in latestLoginSnapshot.docs) {
          if (_matchesDevice(doc.data(), deviceIdentity)) {
            activeSession = doc.data();
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _adminName =
            (data['nama'] ??
                    data['name'] ??
                    authUser.displayName ??
                    authUser.email?.split('@').first ??
                    'Admin ORVIX')
                .toString();
        _adminEmail = (data['email'] ?? authUser.email ?? '-').toString();
        _adminPhoto = (data['foto_profil_path'] ?? data['photoUrl'] ?? '')
            .toString();
        final savedDevice = preferences.getString(
          'active_login_device_${authUser.uid}',
        );
        final device =
            (activeSession?['device'] ?? activeSession?['device_name'] ?? '')
                .toString()
                .trim();
        _activeDeviceName = device.isNotEmpty
            ? device
            : (savedDevice?.trim().isNotEmpty == true
                  ? savedDevice!.trim()
                  : (deviceIdentity['device']!.isEmpty
                        ? 'Perangkat utama'
                        : deviceIdentity['device']!));
        _joinedDate =
            firstLogin ?? createdDate ?? authUser.metadata.creationTime;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _adminName =
            authUser.displayName ??
            authUser.email?.split('@').first ??
            'Admin ORVIX';
        _adminEmail = authUser.email ?? '-';
        _activeDeviceName = 'Perangkat utama';
        _joinedDate = authUser.metadata.creationTime;
      });
    }
  }

  Future<Map<String, String>> _currentDeviceIdentity() async {
    var device = '';
    var platform = '';
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        device = web.browserName.name;
        platform = web.platform ?? 'Web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await info.androidInfo;
        device = '${android.manufacturer} ${android.model}'.trim();
        platform = 'Android ${android.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await info.iosInfo;
        device = ios.name;
        platform = 'iOS ${ios.systemVersion}';
      }
    } catch (_) {}
    return {'device': device, 'platform': platform};
  }

  bool _matchesDevice(
    Map<String, dynamic>? session,
    Map<String, String> identity,
  ) {
    if (session == null || identity['device']!.isEmpty) return false;
    final sessionDevice = (session['device'] ?? session['device_name'] ?? '')
        .toString()
        .trim();
    final sessionPlatform = (session['platform'] ?? '').toString().trim();
    return sessionDevice.toLowerCase() == identity['device']!.toLowerCase() &&
        sessionPlatform.toLowerCase() == identity['platform']!.toLowerCase();
  }

  Future<void> _logoutAdmin() async {
    final preferences = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await preferences.remove('active_login_session_$uid');
      await preferences.remove('active_login_device_$uid');
      await preferences.remove('active_login_platform_$uid');
    }
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _initials() {
    final parts = _adminName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'A' : parts;
  }

  String _joinedDateText() {
    final date = _joinedDate;
    if (date == null) return 'Belum tersedia';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool get _hasPhoto {
    final uri = Uri.tryParse(_adminPhoto.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        // Scrollable Content
        SingleChildScrollView(
          child: Column(
            children: [
              // 1. Header Gradient & Profile Info
              _buildHeader(context),

              // 2. Body Menu Content
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F6F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildStatCards(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('INFORMASI AKUN'),
                      const SizedBox(height: 8),
                      _buildAccountInfoSection(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('HAK AKSES & KEAMANAN'),
                      const SizedBox(height: 8),
                      _buildSecuritySection(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('PREFERENSI & DUKUNGAN'),
                      const SizedBox(height: 8),
                      _buildPreferenceSection(),
                      const SizedBox(height: 24),
                      _buildLogoutButton(),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'ORVIX Management System © 2026',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!widget.embedded)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildBottomNavigationBar(),
          ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(body: Stack(children: [content]));
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8A76D), Color(0xFFEE7E49)],
        ),
      ),
      child: Column(
        children: [
          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 36, height: 36),
              // Title Header
              Column(
                children: const [
                  Text(
                    'SISTEM ORVIX',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Profil Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Notification Badge Button
              Stack(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotifikasiAdminView(),
                          ),
                        ),
                        customBorder: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Avatar & User Details
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Container(
              width: 84,
              height: 84,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _hasPhoto
                  ? ClipOval(
                      child: Image.network(
                        _adminPhoto,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC9825B),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _initials(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC9825B),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _adminName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _adminEmail,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. STAT CARDS ---
  Widget _buildStatCards() {
    return Row(
      children: [
        // Left Stat Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE99570),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STAFF DIAWASI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '12 ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            TextSpan(
                              text: 'Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Stat Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD79A70),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wallet_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BERGABUNG SEJAK',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _joinedDateText(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. SECTION HEADER ---
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.5,
      ),
    );
  }

  // --- 4. SECTION 1: INFORMASI AKUN ---
  Widget _buildAccountInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xFFFFF0EB),
            iconColor: const Color(0xFFE58F6C),
            title: 'Edit Data Pribadi',
            subtitle: 'Nama, telepon, dan identitas admin',
            onTap: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const EditAdminProfileScreen(),
                ),
              );
              if (updated == true) _loadAdminProfile();
            },
          ),
          const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            iconBg: const Color(0xFFFFF0EB),
            iconColor: const Color(0xFFE58F6C),
            title: 'Ubah Kata Sandi & PIN',
            subtitle: 'Terakhir diperbarui 28 hari lalu',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ChangePasswordScreen(),
              ),
            ),
          ),
          const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
          _buildMenuItem(
            icon: Icons.notifications_none_rounded,
            iconBg: const Color(0xFFFFF0EB),
            iconColor: const Color(0xFFE58F6C),
            title: 'Manajemen Notifikasi',
            subtitle: 'Push alert perhitungan & login',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ManajemenNotifikasiAdminView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. SECTION 2: HAK AKSES & KEAMANAN ---
  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.smartphone_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Perangkat Terhubung',
            subtitle: '$_activeDeviceName • Sesi Utama',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ConnectedDevicesScreen(),
              ),
            ),
            trailingBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '1 Online',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
          _buildMenuItem(
            icon: Icons.history_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Riwayat Aktivitas Admin',
            subtitle: 'Log audit dan perubahan sistem',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RiwayatAktivitasAdminPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. SECTION 3: PREFERENSI & DUKUNGAN ---
  Widget _buildPreferenceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            title: 'Pusat Bantuan & Panduan ORVIX',
            subtitle: 'FAQ, manual staff, dan kontak IT',
          ),
          const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
          _buildMenuItem(
            icon: Icons.rotate_right_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            title: 'Versi Aplikasi',
            subtitle: 'Build produksi terbaru',
            showChevron: false,
            trailingBadge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'v2.4.0 (Latest)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REUSABLE MENU ITEM TILE
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailingBadge,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              trailingBadge,
              const SizedBox(width: 6),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
          ],
        ),
      ),
    );
  }

  // --- 7. LOGOUT BUTTON ---
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFCA5A5).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: _logoutAdmin,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text(
              'Keluar dari Akun Admin',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 8. BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF09A72),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE99A78).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Tab
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: _selectedNavIndex == 0,
            onTap: () => Navigator.of(
              context,
            ).pushReplacement(_smoothRoute(const DashboardScreen())),
          ),
          // Analistik Tab
          _buildNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Analitik',
            isSelected: _selectedNavIndex == 1,
            onTap: () => Navigator.of(
              context,
            ).pushReplacement(_smoothRoute(const AnalisisPerhitunganView())),
          ),
          // Profil Tab
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Profil',
            isSelected: _selectedNavIndex == 2,
            isProfileAvatar: true,
            onTap: () => setState(() => _selectedNavIndex = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isProfileAvatar = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isProfileAvatar && isSelected)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFE58F6C),
                  size: 16,
                ),
              ),
            )
          else
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 14,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  PageRoute<void> _smoothRoute(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
