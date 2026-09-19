import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../Services/cloudinary_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Edit Profil Administrator',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        fontFamily: 'Sans-Serif',
      ),
      home: const EditAdminProfileScreen(),
    );
  }
}

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String _initials = 'A';
  String _userId = '';
  String? _profilePhotoUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final name =
          (data['nama'] ??
                  data['name'] ??
                  authUser.displayName ??
                  authUser.email?.split('@').first ??
                  'Admin ORVIX')
              .toString();
      _nameController.text = name;
      _emailController.text = (data['email'] ?? authUser.email ?? '')
          .toString();
      _phoneController.text = (data['phone'] ?? '').toString();
      _userId = (data['user_id'] ?? authUser.uid).toString();
      _profilePhotoUrl = (data['foto_profil_path'] ?? data['photoUrl'])
          ?.toString();
      _initials = name
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0].toUpperCase())
          .join();
      if (_initials.isEmpty) _initials = 'A';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    final selectedPhoto = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (selectedPhoto == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final imageUrl = await CloudinaryService.uploadProfileImage(
        File(selectedPhoto.path),
      );
      if (!mounted) return;
      if (imageUrl == null || imageUrl.isEmpty) {
        throw StateError('Cloudinary tidak mengembalikan URL foto.');
      }
      setState(() => _profilePhotoUrl = imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil gagal diunggah')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Title & Description
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. Avatar & Admin Info
              _buildAvatarSection(),
              const SizedBox(height: 28),

              // 3. Form Input Cards
              _buildNameCard(),
              const SizedBox(height: 16),
              _buildEmailCard(),
              const SizedBox(height: 16),
              _buildPhoneCard(),
              const SizedBox(height: 20),

              // 4. Audit Log Info Box
              _buildInfoNotice(),
              const SizedBox(height: 28),

              // 5. Action Buttons (Simpan & Batal)
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFB83200),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PROFIL ADMINISTRATOR',
              style: TextStyle(
                color: Color(0xFFB83200),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola informasi identitas dan kredensial akun admin Anda',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.3),
        ),
      ],
    );
  }

  // --- 2. AVATAR & USER DETAILS ---
  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          // Circular Avatar with Camera Badge
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCD8CE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                      ? Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB83200),
                            ),
                          ),
                        )
                      : ClipOval(
                          child: Image.network(
                            _profilePhotoUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Text(
                                    _initials,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB83200),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB83200),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: InkWell(
                    onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                    customBorder: const CircleBorder(),
                    child: _isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Admin Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE8E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified, size: 12, color: Color(0xFFB83200)),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB83200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // User Name & ID
          Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ID: $_userId',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. INPUT CARD: NAMA LENGKAP ---
  Widget _buildNameCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _buildCustomInputField(
            controller: _nameController,
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }

  // --- 4. INPUT CARD: EMAIL ADMINISTRATOR ---
  Widget _buildEmailCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Email Administrator'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF0D9488), size: 6),
                    SizedBox(width: 4),
                    Text(
                      'Terverifikasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCustomInputField(
            controller: _emailController,
            icon: Icons.mail_outline_rounded,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  // --- 5. INPUT CARD: NOMOR WHATSAPP ---
  Widget _buildPhoneCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Nomor WhatsApp / Telepon'),
          const SizedBox(height: 8),
          _buildCustomInputField(
            controller: _phoneController,
            icon: Icons.smartphone_rounded,
          ),
        ],
      ),
    );
  }

  // --- 6. AUDIT LOG INFO NOTICE ---
  Widget _buildInfoNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF2F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded, color: Color(0xFF5A6B87), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Perubahan data sensitif akan tercatat otomatis dalam audit log sistem analitik ORVIX demi kepatuhan regulasi keamanan internal.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 7. ACTION BUTTONS ---
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Simpan Perubahan Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading || _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB83200),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Simpan Perubahan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Batal Button
        SizedBox(
          width: 160,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => Navigator.maybePop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFECEAE5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E1E1E),
          fontFamily: 'Sans-Serif',
        ),
        children: [
          TextSpan(text: label),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFB83200)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInputField({
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E1E1E),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();
    if (authUser == null || name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .set({
            'nama': name,
            'phone': _phoneController.text.trim(),
          }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan perubahan profil')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
