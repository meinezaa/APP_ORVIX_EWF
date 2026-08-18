import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    const mainTextColor = Color(0xFF222222);
    const buttonBackground = Color(0xFFFFE5D6);
    const accentColor = Color(0xFFE36F32);
    const dividerColor = Color(0xFF685C52);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            // Warna dasar untuk bagian bawah layar.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // Warna dan titik transisi diambil dari gambar referensi.
                    colors: [
                      Color(0xFFF5DBC4),
                      Color(0xFFEFD2B6),
                      Color(0xFFF1B68A),
                      Color(0xFFF0A777),
                    ],
                    stops: [0, 0.42, 0.56, 1],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Proporsi gambar koin dipertahankan seperti referensi.
            Align(
              alignment: Alignment.topCenter,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  // Foto perlahan transparan ke background, bukan terpotong.
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, 0.38, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Image.asset(
                  'assets/goldencoin.png',
                  width: constraints.maxWidth,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.40,
              left: 24,
              right: 24,
              child: const Text(
                'Selamat Datang di\nORVIX',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  color: mainTextColor,
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.495,
              left: 42,
              right: 42,
              child: const Text(
                'Sistem Managemen Untuk\nPengelolaan Komoditas\ndan Emas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: mainTextColor,
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.61,
              left: 24,
              right: 24,
              child: Row(
                children: const [
                  Expanded(child: Divider(color: dividerColor)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 17),
                    child: Text('Atau', style: TextStyle(color: dividerColor)),
                  ),
                  Expanded(child: Divider(color: dividerColor)),
                ],
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.68,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBackground,
                    elevation: 0,
                    side: const BorderSide(color: accentColor, width: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 37,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah memiliki akun? ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  Semantics(
                    button: true,
                    label: 'Masuk',
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Halaman masuk belum tersedia.'),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 14,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
