import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/users_model.dart'; // Import UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 1. REGISTRASI KHUSUS STAFF
  Future<String?> registerStaff({
    required String email,
    required String password,
    required String nama,
    String? phone,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      String uid = userCred.user!.uid;

      // Buat objek UserModel
      UserModel newUser = UserModel(
        userId: uid,
        nama: nama.trim(),
        email: email.trim(),
        phone: phone?.trim() ?? '',
        role: 'staff',
        status: 'active',
      );

      // Simpan ke Firestore menggunakan .toMap()
      await _firestore.collection('users').doc(uid).set({
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return e.toString();
    }
  }

  // 2. LOGIN (MENGEMBALIKAN USERMODEL)
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      String uid = userCred.user!.uid;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // Konversi Map dari Firestore langsung ke UserModel
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }

      // Auth berhasil, tetapi profil Firestore belum ada. Buat profil dasar
      // agar pengguna tetap dapat masuk setelah reset password.
      final authUser = userCred.user!;
      final fallbackUser = UserModel(
        userId: uid,
        nama: authUser.displayName ?? email.trim().split('@').first,
        email: authUser.email ?? email.trim(),
        phone: authUser.phoneNumber ?? '',
        role: 'staff',
        status: 'active',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(uid)
          .set(fallbackUser.toMap(), SetOptions(merge: true));
      return fallbackUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // 3. AMBIL DATA USER AKTIF (MENGEMBALIKAN USERMODEL)
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 4. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email');
    }
    await _auth.sendPasswordResetEmail(
      email: normalizedEmail,
      actionCodeSettings: ActionCodeSettings(
        // URL HTTPS ini diterima Firebase sebagai continue URL.
        url: 'https://database-app-orvix-ewf.firebaseapp.com/reset-password',
        handleCodeInApp: true,
        androidPackageName: 'com.example.app_pt_ewf',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      ),
    );
  }

  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  // HELPER ERROR
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password yang Anda masukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'operation-not-allowed':
        return 'Login Email/Password belum diaktifkan di Firebase Console.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa koneksi lalu coba lagi.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}
