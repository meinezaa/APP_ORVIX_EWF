class UserModel {
  final String userId;
  final String nama;
  final String email;
  final String phone;
  final String role;
  final String status;

  UserModel({
    required this.userId,
    required this.nama,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
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
    };
  }
}