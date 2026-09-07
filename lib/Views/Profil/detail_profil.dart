import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../Models/users_model.dart';
import '../../Services/auth_services.dart';

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
		_emailController.text = user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
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
		if (photo != null && mounted) setState(() => _selectedPhoto = photo);
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
		setState(() => _birthDate = '${date.day} ${_monthName(date.month)} ${date.year}');
	}

	Future<void> _selectGender() async {
		final gender = await showModalBottomSheet<String>(
			context: context,
			builder: (context) => SafeArea(
				child: Column(mainAxisSize: MainAxisSize.min, children: [
					ListTile(title: const Text('Perempuan'), onTap: () => Navigator.pop(context, 'Perempuan')),
					ListTile(title: const Text('Laki-laki'), onTap: () => Navigator.pop(context, 'Laki-laki')),
				]),
			),
		);
		if (gender != null && mounted) setState(() => _gender = gender);
	}

	Future<void> _saveChanges() async {
		final user = FirebaseAuth.instance.currentUser;
		if (user == null || _nameController.text.trim().isEmpty) return;
		setState(() => _isSaving = true);
		try {
			await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
				'nama': _nameController.text.trim(),
				'phone': _phoneController.text.trim(),
				if (_selectedPhoto != null) 'foto_profil_path': _selectedPhoto!.path,
			}, SetOptions(merge: true));
			if (!mounted) return;
			Navigator.pop(context, true);
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan perubahan profil')));
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

	Widget _buildHeader() => Row(children: [
				_circleButton(Icons.arrow_back, () => Navigator.pop(context)),
				const SizedBox(width: 16),
				const Text('Informasi Profil', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)),
			]);

	Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
				color: Colors.white,
				shape: const CircleBorder(),
				child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Color(0xFF332923), size: 24))),
			);

	Widget _buildAvatar(UserModel? user) {
		final name = user?.nama.trim().isNotEmpty == true ? user!.nama.trim() : 'Pengguna';
		final photoPath = _selectedPhoto?.path ?? _savedPhotoPath;
		return GestureDetector(
			onTap: _pickProfilePhoto,
			child: Column(children: [
			Stack(alignment: Alignment.bottomRight, children: [
				Container(
					width: 132,
					height: 132,
					decoration: BoxDecoration(color: const Color(0xFF192D4B), shape: BoxShape.circle, border: kIsWeb || photoPath == null ? Border.all(color: Colors.white, width: 2) : null),
					alignment: Alignment.center,
					child: !kIsWeb && photoPath != null && photoPath.isNotEmpty
						? ClipOval(child: Image.file(File(photoPath), fit: BoxFit.cover, width: 132, height: 132))
						: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w500)),
				),
				Container(width: 34, height: 34, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Color(0xFFA95208), size: 20)),
			]),
			const SizedBox(height: 22),
			const Text('Ubah Foto Profil', style: TextStyle(color: Color(0xFFE87824), fontSize: 20, fontWeight: FontWeight.w600)),
			]),
		);
	}

	Widget _buildForm() => Container(
				padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
				decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
				child: Column(children: [
					_field('Nama Lengkap', _nameController, Icons.person_outline),
					_field('Email', _emailController, Icons.mail_outline, enabled: false),
					_field('Nomor Telepon', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
					_choiceField('Tanggal Lahir', _birthDate, Icons.calendar_month_outlined, _selectBirthDate),
					_choiceField('Jenis Kelamin', _gender, Icons.people_outline, _selectGender),
				]),
			);

	Widget _field(String label, TextEditingController controller, IconData icon, {bool enabled = true, TextInputType? keyboardType}) => Padding(
				padding: const EdgeInsets.only(bottom: 10),
				child: TextField(
					controller: controller,
					enabled: enabled,
					keyboardType: keyboardType,
					decoration: _inputDecoration(label, icon),
					style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
				),
			);

	Widget _choiceField(String label, String value, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, child: InputDecorator(decoration: _inputDecoration(label, icon), child: Row(children: [Expanded(child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: value.startsWith('Pilih') ? Colors.grey : const Color(0xFF25201D)))), const Icon(Icons.chevron_right, color: Color(0xFFD9BDA8))])));

	InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF655851)), prefixIcon: Icon(icon, color: const Color(0xFFA95208)), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0DAD6))), disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0DAD6))), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA95208), width: 1.5)), contentPadding: const EdgeInsets.symmetric(vertical: 14));

	Widget _buildSaveButton() => SizedBox(height: 56, child: ElevatedButton(onPressed: _isSaving ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE87924), disabledBackgroundColor: const Color(0xFFE87924), foregroundColor: Colors.white, disabledForegroundColor: Colors.white, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Perubahan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))));

	String _monthName(int month) => const ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][month - 1];
}
