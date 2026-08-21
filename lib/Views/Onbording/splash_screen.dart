import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    // Animasi Jatuh dengan efek membal (bounce)
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fallAnimation =
        Tween<Offset>(begin: const Offset(0.0, -3.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _fallController, curve: Curves.bounceOut),
        );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // 1. Jalankan animasi logo jatuh
    await _fallController.forward();

    // 2. Beri jeda sejenak (400ms) agar logo mendarat dengan mulus
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Pindah ke OnboardingScreen (Induk dari Onboarding 1 & 2)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(), // Diarahkan ke OnboardingScreen
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
              child: FadeTransition(opacity: animation, child: child),
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
                  child: Image.asset(
                    'assets/icon_logo.png',
                    width: 140,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.diamond,
                      size: 100,
                      color: Color(0xFFC05C1D),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 5),

              // LOGO TULISAN ORVIX
              Image.asset(
                'assets/text_logo.png',
                width: 160,
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

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
