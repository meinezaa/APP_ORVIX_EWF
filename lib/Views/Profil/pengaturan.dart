import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Models/users_model.dart';
import 'notifikasi.dart';
import 'ganti_password.dart';
import 'tentang_aplikasi.dart';
import 'faq.dart';

class PengaturanView extends StatefulWidget {
  const PengaturanView({super.key});

  @override
  State<PengaturanView> createState() => _PengaturanViewState();
}

class _PengaturanViewState extends State<PengaturanView> {
  Stream<UserModel?> _watchUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          return data == null ? null : UserModel.fromMap(data);
        });
  }

  void _showAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TentangAplikasiView()),
    );
  }

  void _showFaq() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1A06D), Color(0xFFF8C9A9), Color(0xFFFFF8F3)],
            stops: [0.0, 0.38, 0.82],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<UserModel?>(
            stream: _watchUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final name = user?.nama.trim().isNotEmpty == true
                  ? user!.nama.trim()
                  : 'Pengguna';
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildAvatar(user, name),
                  const SizedBox(height: 30),
                  _buildSettingTile(
                    Icons.notifications_none,
                    'Notifikasi',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotifikasiView()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    Icons.key_outlined,
                    'Ganti Password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GantiPasswordView(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSettingTile(
                    Icons.info_outline,
                    'Tentang Aplikasi',
                    onTap: _showAbout,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(Icons.help_outline, 'FAQ', onTap: _showFaq),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      _circleButton(Icons.arrow_back, () => Navigator.pop(context)),
      const SizedBox(width: 12),
      const Text(
        'Pengaturan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: const Color(0xFFE07856), size: 24),
      ),
    ),
  );

  Widget _buildAvatar(UserModel? user, String name) {
    final photoPath = user?.fotoProfilPath;

    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            width: 132,
            height: 132,
            child: _buildAvatarImage(photoPath, name),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFFE87824),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String? photoPath, String name) {
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
      color: const Color(0xFF192D4B),
      alignment: Alignment.center,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFF7A1C), size: 23),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF665E5A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF171311),
                    size: 25,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
