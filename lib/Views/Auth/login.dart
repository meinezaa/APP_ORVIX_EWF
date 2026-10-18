import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main_screen.dart';
import '../Home/beranda_admin.dart';
import '../../Models/users_model.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';
import '../../Services/auth_services.dart';
import 'register.dart';
import 'forgot_password.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instance Service & State Loading
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Controller & Animasi Mengambang (Naik-Turun)
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  // Inisialisasi GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '49789057845-osbscsknt070uaqj2ru8mj7il13ug1qc.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;

    // Setup durasi & perulangan animasi
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Setup pergerakan offset ke atas dan bawah secara halus
    _offsetAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.08)).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  // Arahkan pengguna berdasarkan role yang tersimpan di Firestore.
  void _navigateAfterLogin(UserModel? user) {
    final isAdmin = user?.role.trim().toLowerCase() == 'admin';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isAdmin ? const DashboardScreen() : const MainScreen(),
      ),
    );
  }

  void _onLupaPasswordPressed() {
    final inputEmail = _emailController.text.trim();

    if (inputEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan email Anda terlebih dahulu'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgetpasswordScreen(email: inputEmail),
      ),
    );
  }

  // Fungsi penanganan login Manual (Email & Password)
  Future<void> _handleManualLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Validasi input sederhana
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Password tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil method login dari AuthService
      UserModel? user = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Berhasil! Selamat datang, ${user.nama}.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        _navigateAfterLogin(user);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi penanganan login Google
  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null && mounted) {
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final emailForLink = _emailController.text.trim().toLowerCase();
        final passwordForLink = _passwordController.text;
        if (passwordForLink.isNotEmpty &&
            emailForLink.isNotEmpty &&
            emailForLink != googleUser.email.trim().toLowerCase()) {
          throw StateError(
            'Email pada kolom login harus sama dengan email akun Google.',
          );
        }
        final user = await _authService.signInWithRegisteredGoogle(
          credential: credential,
          googleEmail: googleUser.email,
          passwordForLink: passwordForLink,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil masuk sebagai ${googleUser.email}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        _navigateAfterLogin(user);
      }
    } catch (error) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // 1. LOGO BERLIAN / KOIN (ANIMASI MENGAMBANG NAIK-TURUN)
                Center(
                  child: SlideTransition(
                    position: _offsetAnimation,
                    child: Image.asset(
                      'assets/icon_logo.png',
                      width: 175,
                      height: 175,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.diamond,
                        size: 125,
                        color: Color(0xFFD36A28),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. JUDUL Halaman
                Text(
                  AppStrings.text(context, 'Masuk'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                  ),
                ),

                const SizedBox(height: 32),

                // 3. FIELD EMAIL
                Text(
                  AppStrings.text(context, 'Email'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'contoh@email.com',
                    hintStyle: TextStyle(
                      color: AppTheme.mutedText(context),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD36A28),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. FIELD PASSWORD
                Text(
                  AppStrings.text(context, 'Password'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi',
                    hintStyle: TextStyle(
                      color: AppTheme.mutedText(context),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD36A28),
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.mutedText(context),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _onLupaPasswordPressed,
                    child: Text(
                      AppStrings.text(context, 'Lupa Password?'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD36A28),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 5. TOMBOL UTAMA MASUK (DENGAN INDIKATOR LOADING)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleManualLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD36A28),
                    disabledBackgroundColor: const Color(
                      0xFFD36A28,
                    ).withValues(alpha: 0.6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          AppStrings.text(context, 'Masuk'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // 7. PEMBATAS TEXT "Atau"
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Color(0xFFE0D8D0), thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.text(context, 'Atau'),
                        style: TextStyle(
                          color: AppTheme.mutedText(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFFE0D8D0), thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 8. TOMBOL LOGIN GOOGLE
                OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFFE5884D),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google.png',
                        height: 22,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.g_mobiledata,
                              color: Colors.red,
                              size: 28,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.text(context, 'Continue with Google'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD36A28),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // 9. FOOTER REGISTRASI
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.text(context, 'Belum punya akun? '),
                      style: TextStyle(
                        color: AppTheme.mutedText(context),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const RegisterView(),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.text(context, 'Buat Akun'),
                        style: TextStyle(
                          color: Color(0xFFD36A28),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
