import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Models/users_model.dart';
import '../../Services/app_preferences.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
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

  Future<void> _showThemePicker() async {
    final current = AppPreferences.instance.themeMode;
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppStrings.text(context, 'Pilih Tema')),
        children: [
          for (final theme in [ThemeMode.light, ThemeMode.dark])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, theme),
              child: Row(
                children: [
                  Icon(
                    current == theme
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xFFFF7A1C),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.text(context,
                      theme == ThemeMode.light ? 'Terang' : 'Gelap',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) {
      await AppPreferences.instance.setThemeMode(selected);
    }
  }

  Future<void> _showLanguagePicker() async {
    final current = AppPreferences.instance.locale;
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppStrings.text(context, 'Pilih Bahasa')),
        children: [
          for (final locale in const [Locale('id'), Locale('en')])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, locale),
              child: Row(
                children: [
                  Icon(
                    current == locale
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xFFFF7A1C),
                  ),
                  const SizedBox(width: 12),
                  Text(AppStrings.text(context,
                    locale.languageCode == 'id'
                        ? 'Bahasa Indonesia'
                        : 'English',
                  )),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) {
      await AppPreferences.instance.setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF253034),
                    Color(0xFF151E21),
                    Color(0xFF0B1113),
                  ]
                : const [
                    Color(0xFFF1A06D),
                    Color(0xFFF8C9A9),
                    Color(0xFFFFF8F3),
                  ],
            stops: const [0.0, 0.38, 0.82],
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
                    AppStrings.text(context, 'Notifikasi'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotifikasiView()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    Icons.key_outlined,
                    AppStrings.text(context, 'Ganti Password'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GantiPasswordView(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: AppPreferences.instance,
                    builder: (context, _) => _buildSettingTile(
                      Icons.palette_outlined,
                      AppStrings.text(context, 'Tema'),
                      subtitle: AppStrings.text(context,
                        AppPreferences.instance.themeMode == ThemeMode.dark
                            ? 'Gelap'
                            : 'Terang',
                      ),
                      onTap: _showThemePicker,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: AppPreferences.instance,
                    builder: (context, _) => _buildSettingTile(
                      Icons.language_outlined,
                      AppStrings.text(context, 'Bahasa'),
                      subtitle: AppStrings.text(context,
                        AppPreferences.instance.locale.languageCode == 'en'
                            ? 'English'
                            : 'Bahasa Indonesia',
                      ),
                      onTap: _showLanguagePicker,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSettingTile(
                    Icons.info_outline,
                    AppStrings.text(context, 'Tentang Aplikasi'),
                    onTap: _showAbout,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    Icons.help_outline,
                    AppStrings.text(context, 'FAQ'),
                    onTap: _showFaq,
                  ),
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
      Text(
        AppStrings.text(context, 'Pengaturan'),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
    color: AppTheme.surface(context),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
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
      color: AppTheme.surfaceRaised(context),
      alignment: Alignment.center,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
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
    String? subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppTheme.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 23,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.text(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.mutedText(context),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.mutedText(context),
                    size: 25,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
