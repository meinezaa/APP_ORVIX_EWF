import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
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

                // 1. LOGO BERLIAN
                Center(
                  child: Image.asset(
                    'assets/graphic_logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.diamond,
                      size: 90,
                      color: Color(0xFFD36A28),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. JUDUL Halaman
                const Text(
                  'Masuk',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E1A0C),
                  ),
                ),

                const SizedBox(height: 32),

                // 3. FIELD EMAIL
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E1A0C),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'contoh@email.com',
                    hintStyle: const TextStyle(
                      color: Color(0xFFA09891),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8E0D8)),
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
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E1A0C),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Buat kata sandi minimal 8 karakter',
                    hintStyle: const TextStyle(
                      color: Color(0xFFA09891),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8E0D8)),
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
                        color: const Color(0xFF7A6E65),
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

                // 5. CHECKBOX INGAT SAYA & LUPA PASSWORD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFFD36A28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: Color(0xFFD1C7BD)),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ingat saya',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6E5544),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigasi ke Halaman Lupa Password
                      },
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD36A28),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 6. TOMBOL UTAMA MASUK
                ElevatedButton(
                  onPressed: () {
                    // TODO: Eksekusi Fungsi Login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD36A28),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Masuk',
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
                  children: const [
                    Expanded(
                      child: Divider(color: Color(0xFFE0D8D0), thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Atau',
                        style: TextStyle(
                          color: Color(0xFF8C827A),
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
                  onPressed: () {
                    // TODO: Eksekusi Google Sign-In
                  },
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
                      const Text(
                        'Continue with Google',
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
                    const Text(
                      'Belum punya akun? ',
                      style: TextStyle(color: Color(0xFF6E5544), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigasi ke Halaman Buat Akun
                      },
                      child: const Text(
                        'Buat Akun',
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
