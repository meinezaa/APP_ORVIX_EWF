import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String nama;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? fotoProfilPath;
  final DateTime? createdAt;
  final String? tanggalLahir;
  final String? jenisKelamin;

  UserModel({
    required this.userId,
    required this.nama,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.fotoProfilPath,
    this.createdAt,
    this.tanggalLahir,
    this.jenisKelamin,
  });

  // Mengubah Map Firestore menjadi Objek UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'staff',
      status: map['status'] ?? 'active',
      fotoProfilPath:
          map['foto_profil_path']?.toString() ?? map['photoUrl']?.toString(),
      createdAt: _parseCreatedAt(map['createdAt']),
      tanggalLahir: _stringValue(map['tanggal_lahir'] ?? map['birthDate']),
      jenisKelamin: _stringValue(map['jenis_kelamin'] ?? map['gender']),
    );
  }

  // Mengubah Objek UserModel menjadi Map (jika ingin disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nama': nama,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'foto_profil_path': fotoProfilPath,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
      if (jenisKelamin != null) 'jenis_kelamin': jenisKelamin,
    };
  }

  static DateTime? _parseCreatedAt(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
