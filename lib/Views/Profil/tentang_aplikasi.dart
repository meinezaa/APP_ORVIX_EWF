import 'package:flutter/material.dart';

import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';

class TentangAplikasiView extends StatelessWidget {
  const TentangAplikasiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.pageGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFE07856),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.text(context, 'Tentang Aplikasi'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(context),
                        const SizedBox(height: 18),
                        _buildSectionTitle(context, 'Informasi Aplikasi'),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          'Nama Aplikasi',
                          'ORVIX',
                          Icons.info_rounded,
                        ),
                        _buildInfoRow(
                          context,
                          'Platform',
                          'Android',
                          Icons.phone_android_rounded,
                        ),
                        _buildInfoRow(
                          context,
                          'Bahasa',
                          Localizations.localeOf(context).languageCode == 'en'
                              ? 'English'
                              : 'Bahasa Indonesia',
                          Icons.language_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle(context, 'Dikembangkan Oleh'),
                        const SizedBox(height: 8),
                        _buildDeveloperCard(context),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            AppStrings.text(
                              context,
                              '© 2026 ORVIX. Semua hak dilindungi',
                            ),
                            style: TextStyle(
                              color: AppTheme.mutedText(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 285,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/bg_tentang_aplikasi.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (Theme.of(context).brightness == Brightness.dark)
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon_logo.png',
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 2),
                Image.asset(
                  'assets/orvix_logo.png',
                  width: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.text(
                    context,
                    'ORVIX adalah aplikasi yang membantu Anda memantau harga emas terkini, menghitung nilai emas, serta memudahkan transaksi dengan lebih cepat dan akurat.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.text(context),
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      AppStrings.text(context, title),
      style: TextStyle(
        color: AppTheme.text(context),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE58B52),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.text(context, label),
              style: TextStyle(
                color: AppTheme.text(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppStrings.text(context, value),
            style: TextStyle(
              color: AppTheme.text(context),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE88A52),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppTheme.text(context),
                  fontSize: 13,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '${AppStrings.text(context, 'Tim ORVIX')}\n',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: AppStrings.text(
                      context,
                      'Kami berkomitmen untuk memberikan pengalaman terbaik dalam setiap fitur.',
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
}
