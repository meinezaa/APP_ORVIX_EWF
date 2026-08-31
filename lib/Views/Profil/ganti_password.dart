import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GantiPasswordView extends StatefulWidget {
  const GantiPasswordView({super.key});

  @override
  State<GantiPasswordView> createState() => _GantiPasswordViewState();
}

class _GantiPasswordViewState extends State<GantiPasswordView> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Password requirements checks
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
    setState(() {
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar =
          password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:",.<>?/\\]'));
    });
  }

  bool _validateInputs() {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      _showMessage('Password lama tidak boleh kosong', isError: true);
      return false;
    }

    if (newPassword.isEmpty) {
      _showMessage('Password baru tidak boleh kosong', isError: true);
      return false;
    }

    if (newPassword.length < 8) {
      _showMessage('Password harus minimal 8 karakter', isError: true);
      return false;
    }

    if (!(_hasUppercase && _hasLowercase && _hasNumber && _hasSpecialChar)) {
      _showMessage('Password tidak memenuhi semua persyaratan', isError: true);
      return false;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Password baru tidak cocok', isError: true);
      return false;
    }

    if (oldPassword == newPassword) {
      _showMessage('Password baru tidak boleh sama dengan password lama',
          isError: true);
      return false;
    }

    return true;
  }

  Future<void> _handleChangePassword() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final oldPassword = _oldPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      // Verifikasi password lama dengan melakukan login ulang
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showMessage('Pengguna tidak ditemukan', isError: true);
        return;
      }

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user.email!,
          password: oldPassword,
        );
      } catch (e) {
        _showMessage('Password lama tidak sesuai', isError: true);
        return;
      }

      // Update password
      await user.updatePassword(newPassword);

      if (!mounted) return;

      _showMessage('Password berhasil diubah!', isError: false);

      // Clear input fields
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Kembali ke halaman sebelumnya setelah 1 detik
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'wrong-password' => 'Password lama tidak sesuai',
        'weak-password' => 'Password terlalu lemah',
        'requires-recent-login' => 'Silakan login kembali untuk keamanan',
        _ => e.message ?? 'Gagal mengubah password',
      };
      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage('Gagal mengubah password: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPasswordRequirementItem(bool isMet, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? const Color(0xFFE07856) : Colors.grey.shade300,
          ),
          child: Center(
            child: Icon(
              isMet ? Icons.check : Icons.close,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isMet ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required bool isEnabled,
  }) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE07856),
            width: 2,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFFE07856),
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Ganti Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        titleSpacing: 12,
        elevation: 0,
        backgroundColor: const Color(0xFFE07856),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE07856)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE07856),
              Color(0xFFF8C9A9),
              Color(0xFFFFF8F3),
            ],
            stops: [0.0, 0.4, 0.8],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Silakan masukkan password lama Anda dan buat password baru yang lebih aman.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Old Password Field
                const Text(
                  'Password Lama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _oldPasswordController,
                  label: 'Masukkan password lama',
                  obscure: _obscureOldPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureOldPassword = !_obscureOldPassword;
                    });
                  },
                  isEnabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                // New Password Field
                const Text(
                  'Password Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Masukkan password baru',
                  obscure: _obscureNewPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  isEnabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                // Confirm Password Field
                const Text(
                  'Konfirmasi Password Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Ulangi password baru',
                  obscure: _obscureConfirmPassword,
                  onToggleObscure: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  isEnabled: !_isLoading,
                ),
                const SizedBox(height: 28),
                // Password Requirements
                const Text(
                  'Persyaratan Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPasswordRequirementItem(
                  _hasUppercase,
                  'Memperbolehkan huruf besar (A-Z)',
                ),
                const SizedBox(height: 12),
                _buildPasswordRequirementItem(
                  _hasLowercase,
                  'Memperbolehkan huruf kecil (a-z)',
                ),
                const SizedBox(height: 12),
                _buildPasswordRequirementItem(
                  _hasNumber,
                  'Memperbolehkan angka (0-9)',
                ),
                const SizedBox(height: 12),
                _buildPasswordRequirementItem(
                  _hasSpecialChar,
                  'Memperbolehkan simbol atau tanda baca',
                ),
                const SizedBox(height: 40),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE07856),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

