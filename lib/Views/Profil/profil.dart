import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../Models/historikalkulator_model.dart';
import '../../Models/users_model.dart';
import '../../Services/auth_services.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/history_service.dart';
import '../Auth/login.dart';
import 'detail_profil.dart';
import 'pengaturan.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    await _authService.logout();
    await GoogleSignIn().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.dark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF253034),
                  Color(0xFF151E21),
                  Color(0xFF0B1113),
                ],
                stops: [0.0, 0.5, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3A06D),
                  Color(0xFFF8C29E),
                  Color(0xFFFFE8D8),
                  Color(0xFFFFF8F3),
                ],
                stops: [0.0, 0.38, 0.68, 1.0],
              ),
      ),
      child: SafeArea(
        child: StreamBuilder<List<HistoryModel>>(
          stream: HistoryService.watchHistory(),
          builder: (context, historySnapshot) {
            final history = historySnapshot.data ?? const <HistoryModel>[];
            final counts = _countCalculations(history);
            return StreamBuilder<UserModel?>(
              stream: _watchUser(),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildIdentityCard(user),
                    const SizedBox(height: 18),
                    _buildTipCard(),
                    const SizedBox(height: 30),
                    _buildSummary(counts),
                    const SizedBox(height: 66),
                    _buildLogoutButton(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Stream<UserModel?> _watchUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return null;
          if (data['createdAt'] == null && user.metadata.creationTime != null) {
            data['createdAt'] = user.metadata.creationTime!.toIso8601String();
          }
          return UserModel.fromMap(data);
        });
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 50,
                height: 50,
                child: Material(
                  color: AppTheme.surface(context),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/kepompong-logo.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/text_logo.png', width: 88),
                const SizedBox(width: 10),
                Text(
                  AppStrings.text(context, 'Profil'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PengaturanView()),
                ),
                child: _roundIcon(Icons.settings_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised(context),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Icon(icon, color: AppTheme.text(context), size: 26),
    );
  }

  Widget _buildIdentityCard(UserModel? user) {
    final name = user?.nama.isNotEmpty == true ? user!.nama : 'Pengguna ORVIX';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : (FirebaseAuth.instance.currentUser?.email ?? '-');
    final photoPath = user?.fotoProfilPath;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DetailProfilView()),
      ),
      borderRadius: BorderRadius.circular(15),
      child: _panel(
        padding: const EdgeInsets.all(18),
        color: AppTheme.surface(context),
        showBorder: true,
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 70,
                height: 70,
                child: _buildProfilePhoto(photoPath, name),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text(context),
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.text(context, 'Bergabung sejak'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _monthYear(user?.createdAt ?? DateTime.now()),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildProfilePhoto(String? photoPath, String name) {
    if (photoPath != null && photoPath.startsWith('http')) {
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(name),
      );
    }

    if (!kIsWeb && photoPath != null && photoPath.isNotEmpty) {
      return Image.file(
        File(photoPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitials(name),
      );
    }

    return _buildInitials(name);
  }

  Widget _buildInitials(String name) {
    return Container(
      color: AppTheme.surfaceRaised(context),
      alignment: Alignment.center,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 28),
      ),
    );
  }

  Widget _buildTipCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF202B2E), Color(0xFF172124)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD4B7), Color(0xFFFFE9DB)],
                ),
          border: Border.all(color: AppTheme.border(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 6, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: AppStrings.text(context, 'Hitung ')),
                          TextSpan(
                            text: AppStrings.text(
                              context,
                              'Emas Fisik, Pivot\nPoint & NEST',
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: AppStrings.text(context, ' dengan mudah'),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      AppStrings.text(
                        context,
                        'Gunakan kalkulator ORVIX untuk perhitungan yang cepat, akurat, dan terpercaya.',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Image.asset('assets/home_page.png', fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Map<String, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Theme.of(context).colorScheme.primary,
              size: 19,
            ),
            const SizedBox(width: 5),
            Text(
              AppStrings.text(context, 'Ringkasan Aktivitas'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard(
          Icons.analytics_rounded,
          AppStrings.text(context, 'Total Perhitungan'),
          '${counts['total']}',
          fullWidth: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _summaryCard(
              Icons.balance,
              AppStrings.text(context, 'Emas Fisik'),
              '${counts['emas']}',
            ),
            const SizedBox(width: 10),
            _summaryCard(
              Icons.show_chart,
              AppStrings.text(context, 'Pivot Point'),
              '${counts['pivot']}',
            ),
            const SizedBox(width: 10),
            _summaryCard(Icons.calculate_rounded, 'NEST', '${counts['nest']}'),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    IconData icon,
    String label,
    String value, {
    bool fullWidth = false,
  }) {
    final card = fullWidth
        ? SizedBox(
            height: 96,
            child: _summaryCardContent(icon, label, value, horizontal: true),
          )
        : AspectRatio(
            aspectRatio: 0.82,
            child: _summaryCardContent(icon, label, value),
          );
    return fullWidth
        ? SizedBox(width: double.infinity, child: card)
        : Expanded(child: card);
  }

  Widget _summaryCardContent(
    IconData icon,
    String label,
    String value, {
    bool horizontal = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal ? 24 : 8,
        vertical: horizontal ? 12 : 9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.28
                  : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: horizontal
          ? Row(
              children: [
                Icon(icon, size: 54, color: AppTheme.text(context)),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.text(context, label),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.mutedText(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: AppTheme.text(context)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    AppStrings.text(context, label),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogoutButton() => InkWell(
    onTap: _logout,
    borderRadius: BorderRadius.circular(12),
    child: _panel(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      showBorder: true,
      child: Row(
        children: [
          const Icon(Icons.logout, color: Color(0xFFD82222)),
          const SizedBox(width: 18),
          Text(
            AppStrings.text(context, 'Keluar'),
            style: TextStyle(
              color: AppTheme.mutedText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            size: 28,
            color: AppTheme.mutedText(context),
          ),
        ],
      ),
    ),
  );

  Widget _panel({
    required Widget child,
    required EdgeInsets padding,
    Color? color,
    bool showBorder = false,
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? AppTheme.surface(context),
      borderRadius: BorderRadius.circular(15),
      border: showBorder ? Border.all(color: AppTheme.border(context)) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Map<String, int> _countCalculations(List<HistoryModel> history) => {
    'total': history.length,
    'emas': history
        .where((item) => item.jenisKalkulator.toLowerCase().contains('emas'))
        .length,
    'pivot': history
        .where((item) => item.jenisKalkulator.toLowerCase().contains('pivot'))
        .length,
    'nest': history
        .where((item) => item.jenisKalkulator.toLowerCase().contains('nest'))
        .length,
  };

  String _monthYear(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';
  String _monthName(int month) => const [
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
  ][month - 1];
}

class AppUsageTracker {
  static Timer? _timer;

  static void start() {
    if (_timer != null) return;
    _recordMinute();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _recordMinute());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _recordMinute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('app_usage')
        .doc(date)
        .set({
          'date': date,
          'minutes': FieldValue.increment(1),
        }, SetOptions(merge: true));
  }
}
