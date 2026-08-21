import 'package:flutter/material.dart';

import 'otp_verification.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controller untuk mengambil data dari inputan
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State untuk kelola visibilitas password
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  // State untuk checkbox persetujuan
  bool _isAgreed = true;

  // Skema Warna dari UI
  final Color primaryOrange = const Color(0xFFE05813);
  final Color inputBgColor = const Color(0xFFFAFAFA);
  final Color inputBorderColor = const Color(0xFFEFEFEF);
  final Color labelTextColor = const Color(0xFF212121);
  final Color subtitleTextColor = const Color(0xFF828282);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Judul
              Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                ),
              ),
              const SizedBox(height: 8),

              // Sub-judul / Deskripsi
              Text(
                'Mulai kelola emas fisik Anda dengan mudah dan akurat sekarang juga',
                style: TextStyle(
                  fontSize: 15,
                  color: subtitleTextColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // 2. Input Nama Lengkap
              _buildInputLabel('Nama Lengkap'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Masukkan nama lengkap Anda',
              ),

              const SizedBox(height: 20),

              // 3. Input Email
              _buildInputLabel('Email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'contoh@email.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // 4. Input Nomor Telepon
              _buildInputLabel('Nomor Telepon'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hintText: 'Contoh: 08123456789',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // 5. Input Password
              _buildInputLabel('Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Buat kata sandi minimal 8 karakter',
                isObscure: _isPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 6. Input Konfirmasi Password
              _buildInputLabel('Konfirmasi Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Masukkan kembali kata sandi',
                isObscure: _isConfirmPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 7. Checkbox Syarat & Ketentuan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isAgreed,
                      activeColor: primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          _isAgreed = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleTextColor,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Saya telah menyetujui '),
                          TextSpan(
                            text: 'Syarat dan Ketentuan',
                            style: TextStyle(
                              color: primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' yang berlaku.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 8. Tombol Daftar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continueToOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 9. Teks "Sudah punya akun? Masuk"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleTextColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
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
    );
  }

  // Helper Widget untuk Label Input
  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: labelTextColor,
      ),
    );
  }

  // Helper Widget untuk TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isObscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFA6A6A6),
          fontSize: 14,
        ),
        filled: true,
        fillColor: inputBgColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryOrange, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  void _continueToOtp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    String? message;
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmation.isEmpty) {
      message = 'Lengkapi seluruh data pendaftaran.';
    } else if (!email.contains('@')) {
      message = 'Masukkan alamat email yang valid.';
    } else if (password.length < 8) {
      message = 'Password minimal harus terdiri dari 8 karakter.';
    } else if (password != confirmation) {
      message = 'Konfirmasi password belum sama.';
    } else if (!_isAgreed) {
      message = 'Setujui syarat dan ketentuan terlebih dahulu.';
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OtpVerificationView(phoneNumber: phone),
      ),
    );
  }
}
