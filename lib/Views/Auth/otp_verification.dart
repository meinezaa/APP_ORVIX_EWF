import 'dart:async';
import 'package:flutter/material.dart';

import 'login.dart';

class OtpVerificationView extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationView({
    super.key,
    this.phoneNumber = '0812****6789',
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  // Controller & FocusNode untuk 6 Kotak Input OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Timer Hitung Mundur OTP
  Timer? _timer;
  int _startSeconds = 59;
  bool _canResend = false;

  // Warna Utama dari Desain
  final Color primaryOrange = const Color(0xFFE05813);
  final Color textColorDark = const Color(0xFF212121);
  final Color textColorGrey = const Color(0xFF828282);
  final Color inputBgColor = const Color(0xFFFAFAFA);
  final Color inputBorderColor = const Color(0xFFEFEFEF);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _startSeconds = 59;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _startSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Mendapatkan String Kode OTP Lengkap
  String get _otpCode => _controllers.map((e) => e.text).join();

  // ---------------------------------------------------------------------------
  // DIALOG MODAL REGISTRASI BERHASIL
  // ---------------------------------------------------------------------------
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Icon Centang Hijau
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FADF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF12B76A),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Registrasi Berhasil!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColorDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Akun Anda telah berhasil dibuat. Silakan masuk untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColorGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (context) => const LoginView(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Masuk Sekarang',
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
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOG MODAL REGISTRASI GAGAL
  // ---------------------------------------------------------------------------
  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Icon Silang Merah
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE4E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFF04438),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Registrasi Gagal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColorDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terjadi kesalahan saat membuat akun. Silakan coba lagi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColorGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol Coba Lagi
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Tutup dialog
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryOrange, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Teks Kembali ke Beranda
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigasi ke Beranda/Welcome View
                  },
                  child: Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                      decoration: TextDecoration.underline,
                      decorationColor: primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FUNGSI VERIFIKASI (Contoh Alur Testing)
  // ---------------------------------------------------------------------------
  void _verifyOtp() {
    FocusScope.of(context).unfocus(); // Sembunyikan keyboard

    // Contoh Pengujian:
    // Jika OTP diisi "123456" -> Berhasil
    // Jika selain itu -> Gagal
    if (_otpCode == '123456') {
      _showSuccessDialog();
    } else {
      _showErrorDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Tombol Back bulat di kiri atas
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Judul & Deskripsi
              Text(
                'Verifikasi OTP',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColorDark,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: textColorGrey,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Masukkan kode 6 digit yang telah dikirimkan ke\nnomor telepon Anda ',
                    ),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: TextStyle(
                        color: textColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 6 Box Input Kode OTP (Pindah otomatis saat mengetik)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColorDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: inputBgColor,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryOrange, width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Timer Hitung Mundur
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 18, color: textColorGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Kirim ulang kode dalam ',
                    style: TextStyle(fontSize: 14, color: textColorGrey),
                  ),
                  Text(
                    '00:${_startSeconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColorDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tombol Kirim Ulang
              GestureDetector(
                onTap: _canResend ? _startTimer : null,
                child: Text(
                  'Kirim Ulang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _canResend ? primaryOrange : textColorGrey.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Tombol Verifikasi
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _otpCode.length == 6 ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Verifikasi',
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
    );
  }
}
