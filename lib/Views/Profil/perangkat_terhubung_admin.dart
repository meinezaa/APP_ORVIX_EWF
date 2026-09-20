import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perangkat Terhubung',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        fontFamily: 'Sans-Serif',
      ),
      home: const ConnectedDevicesScreen(),
    );
  }
}

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  Future<Map<String, String>> _currentDeviceIdentity() async {
    var device = '';
    var platform = '';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await deviceInfo.webBrowserInfo;
        device = web.browserName.name;
        platform = web.platform ?? 'Web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await deviceInfo.androidInfo;
        device = '${android.manufacturer} ${android.model}'.trim();
        platform = 'Android ${android.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await deviceInfo.iosInfo;
        device = ios.name;
        platform = 'iOS ${ios.systemVersion}';
      } else {
        platform = defaultTargetPlatform.name;
      }
    } catch (_) {}
    return {'device': device, 'platform': platform};
  }

  Future<Map<String, String?>> _activeSessionContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'id': null, 'device': null, 'platform': null};
    final preferences = await SharedPreferences.getInstance();
    final identity = await _currentDeviceIdentity();
    return {
      'id': preferences.getString('active_login_session_${user.uid}'),
      'device': identity['device'],
      'platform': identity['platform'],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Perangkat Terhubung',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _loginHistoryStream(),
        builder: (context, snapshot) {
          return FutureBuilder<Map<String, String?>>(
            future: _activeSessionContext(),
            builder: (context, activeSessionSnapshot) {
              final activeContext = activeSessionSnapshot.data ?? const {};
              final activeSessionId = activeContext['id'];
              final sessions = _uniqueSessions(
                snapshot.data?.docs ?? const [],
                activeSessionId: activeSessionId,
              );
              final current = _currentSession(
                sessions,
                activeSessionId,
                device: activeContext['device'],
                platform: activeContext['platform'],
              );
              final others = sessions
                  .where((session) => session['_docId'] != current?['_docId'])
                  .toList();
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle Description
                    const Text(
                      'Monitor dan kelola perangkat yang sedang mengakses akun administrator Anda.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Alert Banner (Keamanan Sesi Aktif)
                    _buildSecurityAlertBanner(sessions.length),
                    const SizedBox(height: 24),

                    // 2. Section: Perangkat Saat Ini
                    _buildSectionHeader(
                      title: 'PERANGKAT SAAT INI',
                      trailingText: '• Sesi Utama',
                      trailingColor: const Color(0xFF0D9488),
                    ),
                    const SizedBox(height: 10),
                    _buildCurrentDeviceCard(current),
                    const SizedBox(height: 24),

                    // 3. Section: Perangkat Terdaftar Lainnya
                    _buildSectionHeader(
                      title: 'PERANGKAT TERDAFTAR LAINNYA',
                      trailingText: '${others.length} Perangkat',
                      trailingColor: const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 10),
                    if (others.isEmpty)
                      const Text(
                        'Belum ada perangkat atau sesi lain yang tercatat.',
                      )
                    else
                      ...others.map(
                        (data) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOtherDeviceCard(data),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // 4. Bottom Mass Logout Button & Footer
                    _buildLogoutAllButton(
                      current,
                      onComplete: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sesi di perangkat lain berhasil dikeluarkan.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Tindakan ini akan mengakhiri seluruh sesi aktif kecuali perangkat utama ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _loginHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('login_history')
        .snapshots();
  }

  List<Map<String, dynamic>> _uniqueSessions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    String? activeSessionId,
  }) {
    final sorted = [...docs]
      ..sort((a, b) => _date(b.data()).compareTo(_date(a.data())));
    if (activeSessionId != null) {
      final activeIndex = sorted.indexWhere((doc) => doc.id == activeSessionId);
      if (activeIndex > 0) {
        final activeDoc = sorted.removeAt(activeIndex);
        sorted.insert(0, activeDoc);
      }
    }
    final unique = <String, Map<String, dynamic>>{};
    for (final doc in sorted) {
      final data = {...doc.data(), '_docId': doc.id};
      final key = [
        _text(data, ['device', 'device_name'], 'unknown'),
        _text(data, ['platform'], 'unknown'),
      ].join('|').toLowerCase();
      unique.putIfAbsent(key, () => data);
    }
    return unique.values.toList();
  }

  Map<String, dynamic>? _currentSession(
    List<Map<String, dynamic>> sessions,
    String? activeSessionId, {
    String? device,
    String? platform,
  }) {
    if (device != null && device.isNotEmpty) {
      final matching = sessions
          .where(
            (session) =>
                _deviceKey(session) ==
                _deviceKey({'device': device, 'platform': platform}),
          )
          .toList();
      if (matching.isNotEmpty) return matching.first;
    }
    if (activeSessionId != null) {
      for (final session in sessions) {
        if (session['_docId'] == activeSessionId) return session;
      }
    }
    return sessions.isEmpty ? null : sessions.first;
  }

  String _deviceKey(Map<String, dynamic> data) {
    return [
      _text(data, ['device', 'device_name'], 'unknown'),
      _text(data, ['platform'], 'unknown'),
    ].join('|').toLowerCase();
  }

  DateTime _date(Map<String, dynamic> data) {
    final value = data['logged_in_at'] ?? data['loggedInAt'];
    if (value is Timestamp) return value.toDate().toLocal();
    return DateTime.tryParse('$value') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _text(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  IconData _deviceIcon(String device) {
    final value = device.toLowerCase();
    if (value.contains('android') ||
        value.contains('samsung') ||
        value.contains('iphone') ||
        value.contains('ipad')) {
      return Icons.phone_android_rounded;
    }
    if (value.contains('mac') ||
        value.contains('windows') ||
        value.contains('laptop')) {
      return Icons.laptop_mac_rounded;
    }
    return Icons.devices_other_rounded;
  }

  Future<void> _revokeSession(Map<String, dynamic>? data) async {
    final user = FirebaseAuth.instance.currentUser;
    final docId = data?['_docId']?.toString();
    if (user == null || docId == null || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('login_history')
        .doc(docId)
        .set({
          'revoked': true,
          'revoked_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _revokeOtherDevices(
    Map<String, dynamic>? current,
    VoidCallback onComplete,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final currentKey = current == null ? null : _deviceKey(current);
    final history = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('login_history')
        .get();
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;
    for (final doc in history.docs) {
      if (currentKey != null && _deviceKey(doc.data()) == currentKey) {
        continue;
      }
      batch.set(doc.reference, {
        'revoked': true,
        'revoked_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      changed = true;
    }
    if (changed) await batch.commit();
    if (mounted) onComplete();
  }

  // --- SECTION HEADER HELPER ---
  Widget _buildSectionHeader({
    required String title,
    required String trailingText,
    required Color trailingColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        Text(
          trailingText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: trailingColor,
          ),
        ),
      ],
    );
  }

  // --- 1. SECURITY ALERT BANNER ---
  Widget _buildSecurityAlertBanner(int sessionCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF6EE7B7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF064E3B),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keamanan Sesi Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: 'Akun Anda saat ini aktif di '),
                      TextSpan(
                        text: '$sessionCount perangkat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      TextSpan(
                        text:
                            '. Jika ada perangkat mencurigakan, segera putuskan akses demi integritas data operasional.',
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

  // --- 2. CURRENT DEVICE CARD ---
  Widget _buildCurrentDeviceCard(Map<String, dynamic>? data) {
    final device = _text(data ?? {}, [
      'device',
      'device_name',
    ], 'Perangkat utama');
    final platform = _text(data ?? {}, [
      'platform',
      'browser',
    ], 'Aplikasi ORVIX');
    final ip = _text(data ?? {}, ['ip_address', 'ip'], 'IP tidak tersedia');
    final appVersion = _text(data ?? {}, [
      'app_version',
    ], 'Versi tidak tersedia');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Device Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _deviceIcon(device),
                  color: Color(0xFFEE6C3A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Perangkat Utama\n$platform',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge Online
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF0D9488), size: 6),
                    SizedBox(width: 6),
                    Text(
                      'Online Sekarang',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 6),
                    Text(
                      ip,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.apps_rounded,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: '$appVersion  •  '),
                          TextSpan(
                            text: 'Baru saja',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. OTHER REGISTERED DEVICE CARD ---
  Widget _buildOtherDeviceCard(Map<String, dynamic> data) {
    final device = _text(data, ['device', 'device_name'], 'Perangkat lain');
    final subtitle = _text(data, ['browser', 'platform'], 'Sesi login');
    final locationIp = _text(data, ['ip_address', 'ip'], 'IP tidak tersedia');
    final loggedAt = _date(data);
    final activeStatus =
        'Login ${loggedAt.day}/${loggedAt.month}/${loggedAt.year}';
    final icon = _deviceIcon(device);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Device Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0284C7), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activeStatus,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Location Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    locationIp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Terminate Button
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => _revokeSession(data),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFB91C1C),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Putuskan Sesi Ini',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. MASS LOGOUT BUTTON ---
  Widget _buildLogoutAllButton(
    Map<String, dynamic>? current, {
    required VoidCallback onComplete,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8E1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => _revokeOtherDevices(current, onComplete),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.power_settings_new_rounded,
              color: Color(0xFFB91C1C),
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Keluarkan Dari Semua Perangkat Lain',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
