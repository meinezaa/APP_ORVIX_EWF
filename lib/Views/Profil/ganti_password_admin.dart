import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ganti Kata Sandi',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        fontFamily: 'Sans-Serif',
      ),
      home: const ChangePasswordScreen(),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updatePasswordRequirements);
  }

  void _updatePasswordRequirements() {
    final password = _newPasswordController.text;
    if (!mounted) return;
    setState(() {
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(
        RegExp(r'[!@#$%^&*()_+\-=\[\]{};:",.<>?/\\]'),
      );
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Ganti Kata Sandi',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tag & Header Title
            _buildHeaderSection(),
            const SizedBox(height: 20),

            // 2. Main Card Container
            _buildMainCard(),
            const SizedBox(height: 28),

            // 3. Update Button
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.shield_rounded, size: 16, color: Color(0xFFB83200)),
            SizedBox(width: 6),
            Text(
              'AUTENTIKASI KEAMANAN',
              style: TextStyle(
                color: Color(0xFFB83200),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Ubah Kata Sandi & PIN',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tingkatkan keamanan akses akun administrator dan sistem otorisasi ORVIX.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
        ),
      ],
    );
  }

  // --- 2. MAIN CARD ---
  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Info Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE8E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.published_with_changes_rounded,
                  color: Color(0xFFB83200),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Kata Sandi Akun',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kredensial login utama',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              // Last updated badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFFB83200), size: 6),
                    SizedBox(width: 6),
                    Text(
                      '28 hari lalu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB83200),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Field 1: Kata Sandi Lama
          _buildFieldLabel('Kata Sandi Lama'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _oldPasswordController,
            hintText: 'Masukkan kata sandi lama',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureOld,
            onToggleVisibility: () =>
                setState(() => _obscureOld = !_obscureOld),
          ),
          const SizedBox(height: 18),

          // Field 2: Kata Sandi Baru
          _buildFieldLabel('Kata Sandi Baru'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _newPasswordController,
            hintText: 'Kombinasi minimal 8 karakter',
            prefixIcon: Icons.vpn_key_outlined,
            obscureText: _obscureNew,
            onToggleVisibility: () =>
                setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 16),

          // Password Strength Box
          _buildPasswordStrengthBox(),
          const SizedBox(height: 18),

          // Field 3: Konfirmasi Kata Sandi Baru
          _buildFieldLabel('Konfirmasi Kata Sandi Baru'),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hintText: 'Ulangi kata sandi baru',
            prefixIcon: Icons.verified_user_outlined,
            obscureText: _obscureConfirm,
            onToggleVisibility: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ],
      ),
    );
  }

  // --- PASSWORD STRENGTH METER BOX ---
  Widget _buildPasswordStrengthBox() {
    final strength = [
      _newPasswordController.text.length >= 8,
      _hasUppercase && _hasLowercase,
      _hasNumber,
      _hasSpecialChar,
    ].where((met) => met).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F9F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator Label Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kekuatan Sandi:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                strength == 4 ? 'Kuat (Level 4/4)' : 'Level $strength/4',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: strength == 4
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4 Segment Progress Bars
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index < strength
                        ? const Color(0xFF0D9488)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Checklist Requirements
          _buildRequirementItem(
            'Minimal 8 karakter',
            _newPasswordController.text.length >= 8,
          ),
          const SizedBox(height: 6),
          _buildRequirementItem(
            'Mengandung huruf besar & angka',
            _hasUppercase && _hasLowercase && _hasNumber,
          ),
          const SizedBox(height: 6),
          _buildRequirementItem(
            'Mengandung simbol khusus (@, #, \$, !)',
            _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isMet ? const Color(0xFF0D9488) : const Color(0xFF9CA3AF),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isMet ? const Color(0xFF0F766E) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E1E1E),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // --- 3. SUBMIT BUTTON ---
  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: 220,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB83200),
            elevation: 2,
            shadowColor: const Color(0xFFB83200).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Perbarui Kata Sandi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  bool _validateInputs() {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (oldPassword.isEmpty) {
      _showMessage('Password lama tidak boleh kosong');
      return false;
    }
    if (newPassword.length < 8 ||
        !_hasUppercase ||
        !_hasLowercase ||
        !_hasNumber ||
        !_hasSpecialChar) {
      _showMessage('Password baru belum memenuhi semua persyaratan');
      return false;
    }
    if (newPassword != confirmPassword) {
      _showMessage('Konfirmasi password tidak cocok');
      return false;
    }
    if (oldPassword == newPassword) {
      _showMessage('Password baru tidak boleh sama dengan password lama');
      return false;
    }
    return true;
  }

  Future<void> _handleChangePassword() async {
    if (!_validateInputs()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showMessage('Pengguna tidak ditemukan');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text.trim());
      if (!mounted) return;
      _showMessage('Password berhasil diubah');
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.maybePop(context);
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'wrong-password' ||
        'invalid-credential' => 'Password lama tidak sesuai',
        'weak-password' => 'Password terlalu lemah',
        'requires-recent-login' => 'Silakan login kembali untuk keamanan',
        _ => error.message ?? 'Gagal mengubah password',
      };
      _showMessage(message);
    } catch (_) {
      _showMessage('Gagal mengubah password');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
