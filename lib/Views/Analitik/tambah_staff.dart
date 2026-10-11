import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tambah Staff ORVIX',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        fontFamily: 'Sans-Serif',
      ),
      home: const AddStaffScreen(),
    );
  }
}

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedGender; // null, 'Laki-laki', 'Perempuan'
  String _selectedRole = 'Staff'; // Default selected 'Staff'
  String _selectedStatus = 'Aktif'; // Default selected 'Aktif'
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (name.isEmpty || email.isEmpty) {
      _showMessage('Nama dan email wajib diisi.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Masukkan alamat email yang valid.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final duplicate = await users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        _showMessage('Email tersebut sudah terdaftar.');
        return;
      }

      final userDocument = users.doc();
      final isActive = _selectedStatus == 'Aktif';
      await userDocument.set({
        'user_id': userDocument.id,
        'nama': name,
        'email': email,
        'phone': '',
        'jenis_kelamin': _selectedGender ?? '',
        'role': _selectedRole.toLowerCase(),
        'status': isActive ? 'active' : 'inactive',
        'isActive': isActive,
        'aktif': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff berhasil ditambahkan.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      _showMessage('Gagal menyimpan staff: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section Gradient
            _buildHeader(context),

            // 2. Main Form Container (Overlapping Header)
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form White Card
                    _buildFormCard(),
                    const SizedBox(height: 24),

                    // Simpan Staff Button
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. HEADER GRADIENT ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEE6C3A), Color(0xFFF39256)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // App Logo
          Image.asset('assets/text_logo.png', height: 30, fit: BoxFit.contain),
          const SizedBox(height: 20),

          // Back Button & Page Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1E1E1E),
                    size: 20,
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Tambah Staff',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. FORM CARD ---
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field 1: Nama
          _buildFieldLabel('Nama'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hintText: 'Masukkan nama lengkap',
          ),
          const SizedBox(height: 18),

          // Field 2: Jenis kelamin
          _buildFieldLabel('Jenis kelamin'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  label: 'Laki-laki',
                  isSelected: _selectedGender == 'Laki-laki',
                  onTap: () => setState(() => _selectedGender = 'Laki-laki'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  label: 'Perempuan',
                  isSelected: _selectedGender == 'Perempuan',
                  onTap: () => setState(() => _selectedGender = 'Perempuan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Field 3: Role
          _buildFieldLabel('Role'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  label: 'Admin',
                  isSelected: _selectedRole == 'Admin',
                  onTap: () => setState(() => _selectedRole = 'Admin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  label: 'Staff',
                  isSelected: _selectedRole == 'Staff',
                  onTap: () => setState(() => _selectedRole = 'Staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Field 4: Email
          _buildFieldLabel('Email'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hintText: 'nama@gmail.com',
          ),
          const SizedBox(height: 18),

          // Field 5: Status
          _buildFieldLabel('Status'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  label: 'Aktif',
                  isSelected: _selectedStatus == 'Aktif',
                  onTap: () => setState(() => _selectedStatus = 'Aktif'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  label: 'Nonaktif',
                  isSelected: _selectedStatus == 'Nonaktif',
                  onTap: () => setState(() => _selectedStatus = 'Nonaktif'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- REUSABLE FIELD COMPONENTS ---
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1E1E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3ED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDC5622)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFDC5622)
                      : const Color(0xFFD1D5DB),
                  width: isSelected ? 5.5 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFDC5622)
                    : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. SUBMIT BUTTON ---
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveStaff,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC5622),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Simpan Staff',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
