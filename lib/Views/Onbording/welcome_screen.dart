import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Auth/login.dart'; // Import halaman Login
import '../main_screen.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  // Inisialisasi instance GoogleSignIn
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '49789057845-osbscsknt070uaqj2ru8mj7il13ug1qc.apps.googleusercontent.com',
  );

  // Fungsi untuk menangani proses login Google
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      // Menampilkan pemilih akun Google (Account Picker)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null && context.mounted) {
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil masuk sebagai ${googleUser.email}'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => const MainScreen()),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal masuk dengan Google: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
            // Warna dasar background
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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

            // Gambar Koin
            Align(
              alignment: Alignment.topCenter,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, 0.38, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Image.asset(
                  'assets/goldencoin.png',
                  width: constraints.maxWidth,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 200),
                ),
              ),
            ),

            // Judul Utama
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

            // Subtitle
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

            // Pembatas "Atau"
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

            // Tombol Google
            Positioned(
              top: constraints.maxHeight * 0.68,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _handleGoogleSignIn(context);
                  },
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.g_mobiledata, color: accentColor),
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

            // Footer / Tombol Masuk
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
                      onTap: () {
                        // NAVIGASI LANGSUNG KE LOGIN
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                        );
                      },
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
