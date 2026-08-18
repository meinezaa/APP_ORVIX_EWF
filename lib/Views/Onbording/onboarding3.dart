import 'package:flutter/material.dart';

class OnboardingThree extends StatelessWidget {
  const OnboardingThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFCE2D0), // Cream Peach
              Color(0xFFE5884D), // Terracotta
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // 1. ILUSTRASI GAMBAR ONBOARDING 3
                Image.asset(
                  'assets/onboarding3.png',
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 280,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.security,
                      size: 100,
                      color: Color(0xFFC05C1D),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // 2. JUDUL
                const Text(
                  'Data Aman dan Akses\nTerkontrol',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E1A0C),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. SUBTITLE / DESKRIPSI
                const Text(
                  'ORVIX menjaga aktivitas dan data melalui akses sesuai peran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6E5544),
                  ),
                ),

                const Spacer(flex: 3),

                // 4. INDIKATOR HALAMAN (DOT 3 AKTIF)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dot 1 (Inaktif)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dot 2 (Inaktif)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dot 3 (Aktif)
                    Container(
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD36A28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
