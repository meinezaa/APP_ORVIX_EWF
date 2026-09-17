import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_historidetail.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Riwayat Login ORVIX',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F6F2),
        fontFamily: 'Sans-Serif',
      ),
      home: const LoginHistoryScreen(),
    );
  }
}

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('login_history')
          .snapshots(),
      builder: (context, snapshot) {
        final loginLogs =
            (snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .map(_loginLogFromFirestore)
                .toList()
              ..sort((a, b) {
                final aTime = a['timestamp'] as DateTime?;
                final bTime = b['timestamp'] as DateTime?;
                final aMillis = aTime?.millisecondsSinceEpoch ?? 0;
                final bMillis = bTime?.millisecondsSinceEpoch ?? 0;
                return bMillis.compareTo(aMillis);
              });

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Bar / Appbar Header
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // 2. Log Activity Summary Card
                  _buildSummaryCard(loginLogs.length),
                  const SizedBox(height: 24),

                  // 3. Section Title & Month Filter
                  _buildSectionHeader(),
                  const SizedBox(height: 12),

                  // 4. Staff Login History List
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: loginLogs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = loginLogs[index];
                      return _buildLogTile(context, log);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _loginLogFromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final name = data['nama']?.toString().trim();
    final safeName = name == null || name.isEmpty ? 'Pengguna' : name;
    final initials = safeName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final timestamp = data['logged_in_at'] ?? data['loggedInAt'];
    final date = timestamp is Timestamp
        ? timestamp.toDate().toLocal()
        : timestamp is DateTime
        ? timestamp.toLocal()
        : null;
    final formattedTime = date == null
        ? 'Waktu login belum tersedia'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB';
    final role = data['role']?.toString().trim() ?? 'Staff';
    final isAdmin = role.toLowerCase() == 'admin';

    return {
      'initials': initials.isEmpty ? 'P' : initials,
      'avatarBg': isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
      'avatarTextColor': isAdmin
          ? const Color(0xFFD97706)
          : const Color(0xFF2563EB),
      'name': safeName,
      'role': role,
      'badgeText': isAdmin ? 'Admin' : 'Login Sistem',
      'badgeBg': isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
      'badgeTextColor': isAdmin
          ? const Color(0xFFD97706)
          : const Color(0xFF2563EB),
      'time': formattedTime,
      'device': data['email']?.toString() ?? '',
      'timestamp': date,
      'rawData': data,
      'documentId': document.id,
      'userId':
          data['user_id']?.toString() ?? document.reference.parent.parent?.id,
      'photoUrl':
          data['foto_profil_path']?.toString() ?? data['photoUrl']?.toString(),
    };
  }

  String? _photoUrl(Map<String, dynamic> data) {
    final value = data['photoUrl']?.toString().trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? value
        : null;
  }

  Widget _profileAvatar(Map<String, dynamic> log) {
    final existingPhoto = _photoUrl(log);
    final userId = log['userId']?.toString();
    if (existingPhoto != null || userId == null || userId.isEmpty) {
      return _initialsAvatar(log, existingPhoto);
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final photo = data == null
            ? null
            : _photoUrl({
                'photoUrl':
                    data['foto_profil_path']?.toString() ??
                    data['photoUrl']?.toString(),
              });
        return _initialsAvatar(log, photo);
      },
    );
  }

  Widget _initialsAvatar(Map<String, dynamic> log, String? photoUrl) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: log['avatarBg'], shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: photoUrl == null
          ? Center(
              child: Text(
                log['initials'],
                style: TextStyle(
                  color: log['avatarTextColor'],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  log['initials'],
                  style: TextStyle(
                    color: log['avatarTextColor'],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        Column(
          children: const [
            Text(
              'AKTIVITAS ORVIX',
              style: TextStyle(
                color: Color(0xFFEE6C3A),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Riwayat Login ke Sistem',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- LOG ACTIVITY SUMMARY CARD ---
  Widget _buildSummaryCard(int totalLogin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Center Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Log Aktivitas Login',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Catatan riwayat sesi &\nautentikasi staff',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Right Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEE6C3A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalLogin Tercatat',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION HEADER ---
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Staff & Waktu Login',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'September 2026',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  // --- LOG TILE CARD ---
  Widget _buildLogTile(BuildContext context, Map<String, dynamic> log) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => LoginDetailScreen(loginData: log),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            _profileAvatar(log),
            const SizedBox(width: 12),

            // Content Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge Text (Login Sistem / Admin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: log['badgeBg'],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          log['badgeText'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: log['badgeTextColor'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log['role'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${log['time']} • ${log['device']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron Arrow Icon
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
          ],
        ),
      ),
    );
  }
}
