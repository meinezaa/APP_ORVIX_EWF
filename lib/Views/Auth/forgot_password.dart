import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Services/auth_services.dart';

class ForgetpasswordScreen extends StatefulWidget {
  final String email; // Menerima email dinamis dari halaman sebelumnya

  const ForgetpasswordScreen({
    super.key,
    required this.email, // Wajib diisi saat dipanggil
  });

  @override
  State<ForgetpasswordScreen> createState() => _ForgetpasswordScreenState();
}

class _ForgetpasswordScreenState extends State<ForgetpasswordScreen> {
  final AuthService _authService = AuthService();
  bool _isSending = false;
  String? _message;
  bool _sentSuccessfully = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendResetEmail());
  }

  Future<void> _sendResetEmail() async {
    if (_isSending || _cooldownSeconds > 0) return;

    setState(() {
      _isSending = true;
      _message = null;
      _sentSuccessfully = false;
    });

    try {
      await _authService.sendPasswordResetEmail(widget.email);
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sentSuccessfully = true;
        _message =
            'Link reset password sudah dikirim. Periksa inbox atau folder spam email Anda.';
      });
      _startCooldown();
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Password reset Firebase error: ${error.code} - ${error.message}',
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _message = _authErrorMessage(error.code);
      });
      _startCooldown();
    } catch (error) {
      debugPrint('Password reset unexpected error: $error');
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _message = 'Email reset password gagal dikirim. Silakan coba lagi.';
      });
      _startCooldown();
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email tersebut belum terdaftar.';
      case 'too-many-requests':
        return 'Terlalu banyak permintaan dari Firebase. Tunggu beberapa menit sebelum mencoba lagi.';
      case 'operation-not-allowed':
        return 'Login Email/Password belum diaktifkan di Firebase Console.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa koneksi lalu coba lagi.';
      case 'invalid-continue-uri':
      case 'unauthorized-continue-uri':
        return 'Konfigurasi link reset Firebase belum diizinkan. Periksa Authorized domains.';
      default:
        return 'Email reset password gagal dikirim. Silakan coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE27C3B), // Warna Oranye Atas
              Color(0xFFEA9C68),
              Color(0xFFFCF3EC), // Warna Krem Bawah
            ],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER (Tombol Back & Judul)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Lupa Password',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // KARTU UTAMA
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF221914),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TEKS EMAIL DINAMIS
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text:
                              'Link untuk mengatur ulang password akan dikirimkan ke email ',
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 13,
                            color: Color(0xFF8A827C),
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: widget.email, // <--- EMAIL DINAMIS USER
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF221914),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                      Icon(
                        _sentSuccessfully
                            ? Icons.mark_email_read_outlined
                            : Icons.mail_outline,
                        size: 72,
                        color: _sentSuccessfully
                            ? const Color(0xFF3D9B60)
                            : const Color(0xFFD36A28),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isSending
                            ? 'Mengirim email reset password...'
                            : (_message ?? 'Menyiapkan pengiriman email...'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A827C),
                          height: 1.4,
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                            onPressed: _isSending || _cooldownSeconds > 0
                              ? null
                              : _sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE631B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isSending
                              ? 'Mengirim...'
                              : _cooldownSeconds > 0
                              ? 'Tunggu ${_cooldownSeconds}s'
                              : 'Kirim Ulang Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
    );
  }
}
