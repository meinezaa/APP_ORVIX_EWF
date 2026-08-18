import 'package:flutter/material.dart';

class OnboardingTwo extends StatelessWidget {
  const OnboardingTwo({super.key});

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
              Color(0xFFE5884D), // Terracotta Oranye
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

                // 1. ILUSTRASI GAMBAR ONBOARDING 2
                Image.asset(
                  'assets/onboarding2.png',
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 280,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image,
                      size: 100,
                      color: Color(0xFFC05C1D),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // 2. JUDUL
                const Text(
                  'Hitung dengan Cepat dan Akurat',
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
                  'Perhitungan Emas Fisik dan Pivot Point dalam proses yang lebih cepat dan praktis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6E5544),
                  ),
                ),

                const Spacer(flex: 3),

                // 4. INDIKATOR HALAMAN (DOT 2 AKTIF)
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
                    // Dot 2 (Aktif)
                    Container(
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD36A28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dot 3 (Inaktif)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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
