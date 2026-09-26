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
    if (user == null) {
      return {'id': null, 'uid': null, 'device': null, 'platform': null};
    }
    final preferences = await SharedPreferences.getInstance();
    final identity = await _currentDeviceIdentity();
    return {
      'id': preferences.getString('active_login_session_${user.uid}'),
      'uid': user.uid,
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
              final activeUserId = activeContext['uid'];
              final sessions = _uniqueSessions(
                snapshot.data?.docs ?? const [],
                activeSessionId: activeSessionId,
              );
              final current = _currentSession(
                sessions,
                activeSessionId,
                userId: activeUserId,
                device: activeContext['device'],
                platform: activeContext['platform'],
              );
              final others = sessions
                  .where((session) => session['_docId'] != current?['_docId'])
                  .toList();
              final onlineCount = sessions.where(_isOnline).length;
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
                    _buildSecurityAlertBanner(onlineCount),
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
      final ownerId = doc.reference.parent.parent?.id;
      if (ownerId == null) continue;
      data['_ownerUid'] = ownerId;
      final deviceName = (data['device'] ?? data['device_name'])
          ?.toString()
          .trim();
      if (deviceName == null ||
          deviceName.isEmpty ||
          deviceName.toLowerCase() == 'perangkat lain' ||
          deviceName.toLowerCase() == 'tidak tersedia') {
        continue;
      }
      final key = [
        ownerId,
        _text(data, ['device', 'device_name'], 'unknown'),
        _text(data, ['platform'], 'unknown'),
      ].join('|').toLowerCase();

      if (unique.containsKey(key)) continue;
      unique[key] = data;
    }
    return unique.values.toList();
  }

  Map<String, dynamic>? _currentSession(
    List<Map<String, dynamic>> sessions,
    String? activeSessionId, {
    String? userId,
    String? device,
    String? platform,
  }) {
    if (activeSessionId != null && userId != null) {
      for (final session in sessions) {
        if (session['_ownerUid'] == userId &&
            session['_docId'] == activeSessionId) {
          return session;
        }
      }
    }
    if (device != null && device.isNotEmpty) {
      final matching = sessions
          .where(
            (session) =>
                session['_ownerUid'] == userId &&
                _deviceKey(session) ==
                    _deviceKey({'device': device, 'platform': platform}),
          )
          .toList();
      if (matching.isNotEmpty) return matching.first;
    }
    return null;
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

  bool _isOnline(Map<String, dynamic> data) {
    if (data['revoked'] == true || data['is_online'] == false) return false;
    final lastActivity =
        data['last_seen'] ?? data['logged_in_at'] ?? data['loggedInAt'];
    if (lastActivity is! Timestamp) return false;
    return DateTime.now().difference(lastActivity.toDate()) <=
        const Duration(minutes: 2);
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

  Future<bool> _revokeSession(Map<String, dynamic>? data) async {
    final ownerId = data?['_ownerUid']?.toString();
    final docId = data?['_docId']?.toString();
    if (ownerId == null || data == null || docId == null || docId.isEmpty) {
      return false;
    }
    final sessionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .collection('login_history')
        .doc(docId);
    await sessionRef.set({
      'revoked': true,
      'revoked_at': FieldValue.serverTimestamp(),
      'is_online': false,
      'last_seen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final updated = await sessionRef.get();
    return updated.data()?['revoked'] == true;
  }

  Future<bool> _reconnectSession(Map<String, dynamic>? data) async {
    final ownerId = data?['_ownerUid']?.toString();
    final docId = data?['_docId']?.toString();
    if (ownerId == null || docId == null || docId.isEmpty) return false;
    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .collection('login_history');
    final history = await historyRef.get();
    final deviceKey = _deviceKey(data!);
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;
    for (final doc in history.docs) {
      if (_deviceKey({...doc.data(), '_ownerUid': ownerId}) != deviceKey) {
        continue;
      }
      batch.set(doc.reference, {
        'revoked': false,
        'revoked_at': FieldValue.delete(),
      }, SetOptions(merge: true));
      changed = true;
    }
    if (!changed) return false;
    await batch.commit();
    final updated = await historyRef.doc(docId).get();
    return updated.data()?['revoked'] != true;
  }

  Future<void> _handleRevoke(Map<String, dynamic> data) async {
    try {
      final success = await _revokeSession(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Sesi perangkat berhasil diputuskan.'
                : 'Sesi gagal diputuskan.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memutuskan sesi: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReconnect(Map<String, dynamic> data) async {
    try {
      final success = await _reconnectSession(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Perangkat berhasil disambungkan kembali.'
                : 'Perangkat gagal disambungkan.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyambungkan perangkat: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        'is_online': false,
        'last_seen': FieldValue.serverTimestamp(),
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
    final account = _text(data, ['email', 'name', 'nama'], 'Admin');
    final subtitle = _text(data, ['browser', 'platform'], 'Sesi login');
    final locationIp = _text(data, ['ip_address', 'ip'], 'IP tidak tersedia');
    final loggedAt = _date(data);
    final isRevoked = data['revoked'] == true;
    final isOnline = _isOnline(data);
    final activeStatus = isOnline
        ? 'Online'
        : isRevoked
        ? 'Terputus'
        : 'Offline · Login ${loggedAt.day}/${loggedAt.month}/${loggedAt.year}';
    final statusColor = isOnline
        ? const Color(0xFF0F766E)
        : const Color(0xFF4B5563);
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
                      account,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
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
                  color: isOnline
                      ? const Color(0xFFCCFBF1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activeStatus,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: statusColor),
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

          Row(
            children: [
              Expanded(
                child: _buildSessionActionButton(
                  icon: Icons.logout_rounded,
                  label: 'Putuskan Sesi',
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFB91C1C),
                  onPressed: isRevoked ? null : () => _handleRevoke(data),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSessionActionButton(
                  icon: Icons.link_rounded,
                  label: 'Sambungkan',
                  backgroundColor: const Color(0xFFECFDF5),
                  foregroundColor: const Color(0xFF047857),
                  onPressed: () => _handleReconnect(data),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foregroundColor, size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
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
