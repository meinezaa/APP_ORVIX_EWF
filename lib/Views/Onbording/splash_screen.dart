import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_screen.dart';
import 'onboarding_screen.dart'; // Hanya perlu meng-import OnboardingScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fallController;
  late Animation<Offset> _fallAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _wordmarkScaleAnimation;
  late Animation<double> _wordmarkOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi Jatuh dengan efek membal (bounce)
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );

    _fallAnimation =
        Tween<Offset>(begin: const Offset(0.0, -3.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _fallController, curve: Curves.bounceOut),
        );
    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _fallController,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _fallController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );
    _wordmarkScaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _fallController,
        curve: const Interval(0.42, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _wordmarkOpacityAnimation = CurvedAnimation(
      parent: _fallController,
      curve: const Interval(0.42, 0.72, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // 1. Jalankan animasi logo jatuh
    await _fallController.forward();

    // 2. Tahan sebentar agar splash terasa selesai sebelum berpindah halaman
    await Future.delayed(const Duration(milliseconds: 4200));

    // 3. Pertahankan sesi login jika pengguna masih terautentikasi.
    if (mounted) {
      final nextPage = FirebaseAuth.instance.currentUser != null
          ? const MainScreen()
          : const OnboardingScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (context, animation, secondaryAnimation) => nextPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.08);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _fallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE5884D), // Terracotta
              Color(0xFFFCE2D0), // Cream Peach
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 4),

              // LOGO BERLIAN DENGAN ANIMASI JATUH
              RepaintBoundary(
                child: SlideTransition(
                  position: _fallAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        'assets/icon_logo.png',
                        width: 200,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.diamond,
                              size: 140,
                              color: Color(0xFFC05C1D),
                            ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 5),

              // LOGO TULISAN ORVIX
              FadeTransition(
                opacity: _wordmarkOpacityAnimation,
                child: ScaleTransition(
                  scale: _wordmarkScaleAnimation,
                  child: Image.asset(
                    'assets/text_logo.png',
                    width: 220,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'ORVIX',
                      style: TextStyle(
                        color: Color(0xFFC05C1D),
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
