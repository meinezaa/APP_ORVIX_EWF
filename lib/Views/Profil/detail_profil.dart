import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Models/users_model.dart';
import '../../Services/auth_services.dart';
import '../../Services/cloudinary_services.dart';

class DetailProfilView extends StatefulWidget {
  const DetailProfilView({super.key});

  @override
  State<DetailProfilView> createState() => _DetailProfilViewState();
}

class _DetailProfilViewState extends State<DetailProfilView> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final Future<UserModel?> _userFuture;

  String _birthDate = 'Pilih tanggal lahir';
  String _gender = 'Pilih jenis kelamin';
  bool _isSaving = false;

  XFile? _selectedPhoto;
  String? _savedPhotoPath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<UserModel?> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    _nameController.text = user?.nama ?? '';
    _emailController.text =
        user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _savedPhotoPath = user?.fotoProfilPath;
    return user;
  }

  Future<void> _pickProfilePhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (photo != null && mounted) {
      setState(() => _selectedPhoto = photo);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 8, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(
      () => _birthDate = '${date.day} ${_monthName(date.month)} ${date.year}',
    );
  }

  Future<void> _selectGender() async {
    final gender = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Perempuan'),
              onTap: () => Navigator.pop(context, 'Perempuan'),
            ),
            ListTile(
              title: const Text('Laki-laki'),
              onTap: () => Navigator.pop(context, 'Laki-laki'),
            ),
          ],
        ),
      ),
    );
    if (gender != null && mounted) setState(() => _gender = gender);
  }

  // FUNGSI SIMPAN PERUBAHAN (DILENGKAPI UPLOAD CLOUDINARY)
  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _savedPhotoPath;

      // 1. Jika pengguna memilih foto baru dari galeri, upload ke Cloudinary
      if (_selectedPhoto != null) {
        photoUrl = await CloudinaryService.uploadProfileImage(
          File(_selectedPhoto!.path),
        );
      }

      // 2. Simpan data profil & URL Cloudinary ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nama': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        ...?photoUrl == null
            ? null
            : <String, String>{'foto_profil_path': photoUrl},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF4AA7A),
              Color(0xFFF8C9A9),
              Color(0xFFFFE8D8),
              Color(0xFFFFF8F3),
            ],
            stops: [0.0, 0.3, 0.68, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<UserModel?>(
            future: _userFuture,
            builder: (context, snapshot) => ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildAvatar(snapshot.data),
                const SizedBox(height: 28),
                _buildForm(),
                const SizedBox(height: 96),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      _circleButton(Icons.arrow_back, () => Navigator.pop(context)),
      const SizedBox(width: 16),
      const Text(
        'Informasi Profil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: const Color(0xFF332923), size: 24),
      ),
    ),
  );

  // WIDGET AVATAR (MENDUKUNG FOTO FILE BARU & URL NETWORK CLOUDINARY)
  Widget _buildAvatar(UserModel? user) {
    final name = user?.nama.trim().isNotEmpty == true
        ? user!.nama.trim()
        : 'Pengguna';

    return GestureDetector(
      onTap: _pickProfilePhoto,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  color: Color(0xFF192D4B),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ClipOval(child: _buildAvatarContent(name)),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFFA95208),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Ubah Foto Profil',
            style: TextStyle(
              color: Color(0xFFE87824),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // LOGIKA TAMPILAN GAMBAR AVATAR
  Widget _buildAvatarContent(String name) {
    // 1. Jika ada foto baru yang dipilih dari galeri
    if (_selectedPhoto != null) {
      return Image.file(
        File(_selectedPhoto!.path),
        fit: BoxFit.cover,
        width: 132,
        height: 132,
      );
    }

    // 2. Jika foto tersimpan berbentuk URL (Cloudinary)
    if (_savedPhotoPath != null && _savedPhotoPath!.startsWith('http')) {
      return Image.network(
        _savedPhotoPath!,
        fit: BoxFit.cover,
        width: 132,
        height: 132,
        errorBuilder: (context, error, stackTrace) => _buildInitials(name),
      );
    }

    // 3. Jika foto tersimpan berbentuk File lokal (legacy)
    if (_savedPhotoPath != null && _savedPhotoPath!.isNotEmpty && !kIsWeb) {
      return Image.file(
        File(_savedPhotoPath!),
        fit: BoxFit.cover,
        width: 132,
        height: 132,
        errorBuilder: (context, error, stackTrace) => _buildInitials(name),
      );
    }

    // 4. Default: Tampilkan inisial huruf nama
    return _buildInitials(name);
  }

  Widget _buildInitials(String name) {
    return Text(
      name.substring(0, 1).toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildForm() => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      children: [
        _field('Nama Lengkap', _nameController, Icons.person_outline),
        _field('Email', _emailController, Icons.mail_outline, enabled: false),
        _field(
          'Nomor Telepon',
          _phoneController,
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _choiceField(
          'Tanggal Lahir',
          _birthDate,
          Icons.calendar_month_outlined,
          _selectBirthDate,
        ),
        _choiceField(
          'Jenis Kelamin',
          _gender,
          Icons.people_outline,
          _selectGender,
        ),
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  Widget _choiceField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: _inputDecoration(label, icon),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: value.startsWith('Pilih')
                    ? Colors.grey
                    : const Color(0xFF25201D),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFD9BDA8)),
        ],
      ),
    ),
  );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF655851)),
        prefixIcon: Icon(icon, color: const Color(0xFFA95208)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0DAD6)),
        ),
        disabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0DAD6)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFA95208), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      );

  Widget _buildSaveButton() => SizedBox(
    height: 56,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE87924),
        disabledBackgroundColor: const Color(0xFFE87924),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Simpan Perubahan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
    ),
  );

  String _monthName(int month) => const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ][month - 1];
}
