import 'package:flutter/material.dart';

class TentangAplikasiView extends StatelessWidget {
  const TentangAplikasiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EDE6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE88A52),
              Color(0xFFF0B184),
              Color(0xFFF4CBAA),
              Color(0xFFF9EEE7),
              Color(0xFFF9EEE7),
            ],
            stops: [0.0, 0.22, 0.42, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18, top: 6, bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Color(0xFFE88A52), size: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Tentang Aplikasi',
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
                        _buildHeroCard(),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Informasi Aplikasi'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Nama Aplikasi', 'ORVIX', Icons.info_rounded),
                        _buildInfoRow('Versi', '1.0.0', Icons.layers_outlined),
                        _buildInfoRow('Tanggal Rilis', '15 September 2026', Icons.calendar_month_rounded),
                        _buildInfoRow('Platform', 'Android', Icons.phone_android_rounded),
                        _buildInfoRow('Bahasa', 'Indonesia', Icons.language_rounded),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Dikembangkan Oleh'),
                        const SizedBox(height: 8),
                        _buildDeveloperCard(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('Lainnya'),
                        const SizedBox(height: 8),
                        _buildSecurityRow(),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            '© 2026 ORVIX. Semua hak dilindungi',
                            style: TextStyle(
                              color: Color(0xFF6C5F5A),
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

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      height: 255,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.08),
                  BlendMode.srcOver,
                ),
                child: Image.asset(
                  'assets/bg_tentang_aplikasi.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
                const Text(
                  'ORVIX adalah aplikasi yang membantu Anda memantau harga emas terkini, menghitung nilai emas, serta memudahkan transaksi dengan lebih cepat dan akurat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2E2A28),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF2E2A28),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
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
              label,
              style: const TextStyle(
                color: Color(0xFF2B2B2B),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2B2B2B),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
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
              text: const TextSpan(
                style: TextStyle(
                  color: Color(0xFF2B2B2B),
                  fontSize: 13,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: 'Tim ORVIX\n',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'Kami berkomitmen untuk memberikan pengalaman terbaik dalam setiap fitur.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE88A52),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Keamanan Aplikasi',
              style: TextStyle(
                color: Color(0xFF2B2B2B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF2B2B2B), size: 28),
        ],
      ),
    );
  }
}

