import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/users_model.dart'; // Import UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _sessionRevocationSubscription;
  Timer? _presenceTimer;
  DocumentReference<Map<String, dynamic>>? _activeSessionReference;

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
      await _removeLegacyPasswordFields(uid);

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // Konversi Map dari Firestore langsung ke UserModel
        final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        await recordLogin(user: user);
        return user;
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
      await recordLogin(user: fallbackUser);
      return fallbackUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _removeLegacyPasswordFields(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'password': FieldValue.delete(),
        'passwordHash': FieldValue.delete(),
        'password_hash': FieldValue.delete(),
      });
    } catch (_) {}
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

  // Catat login agar admin dapat melihat riwayat sesi di dashboard.
  // Kegagalan pencatatan tidak boleh menghalangi pengguna masuk aplikasi.
  Future<void> recordLogin({UserModel? user}) async {
    final authUser = currentUser;
    if (authUser == null) return;

    try {
      final profile = user ?? await getCurrentUserData();
      final loginName = profile?.nama.isNotEmpty == true
          ? profile!.nama
          : (authUser.displayName ??
                authUser.email?.split('@').first ??
                'Pengguna');
      final metadata = await _loginMetadata();
      final previousLogins = await _firestore
          .collection('users')
          .doc(authUser.uid)
          .collection('login_history')
          .get();
      final isNewDevice = previousLogins.docs.every(
        (doc) => !_sameSessionDevice(doc.data(), metadata),
      );

      final loginRef = await _firestore
          .collection('users')
          .doc(authUser.uid)
          .collection('login_history')
          .add({
            'user_id': authUser.uid,
            'nama': loginName,
            'name': loginName,
            'role': profile?.role ?? 'staff',
            'email': authUser.email ?? profile?.email ?? '',
            'foto_profil_path': profile?.fotoProfilPath,
            'is_new_device': isNewDevice,
            'is_online': true,
            'last_seen': FieldValue.serverTimestamp(),
            'logged_in_at': FieldValue.serverTimestamp(),
            'loggedInAt': FieldValue.serverTimestamp(),
            ...metadata,
          });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'active_login_session_${authUser.uid}',
        loginRef.id,
      );
      await preferences.setString(
        'active_login_device_${authUser.uid}',
        metadata['device'] ?? '',
      );
      await preferences.setString(
        'active_login_platform_${authUser.uid}',
        metadata['platform'] ?? '',
      );
      await monitorCurrentSession();
    } catch (_) {}
  }

  Future<void> monitorCurrentSession() async {
    final authUser = currentUser;
    if (authUser == null) return;

    final preferences = await SharedPreferences.getInstance();
    final savedSessionId = preferences.getString(
      'active_login_session_${authUser.uid}',
    );
    final localMetadata = await _loginMetadata();
    final history = await _firestore
        .collection('users')
        .doc(authUser.uid)
        .collection('login_history')
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? selectedSession;
    if (savedSessionId != null && savedSessionId.isNotEmpty) {
      for (final doc in history.docs) {
        if (doc.id == savedSessionId &&
            doc.data()['revoked'] != true &&
            _sameSessionDevice(doc.data(), localMetadata)) {
          selectedSession = doc;
          break;
        }
      }
    }
    selectedSession ??= _latestMatchingSession(history.docs, localMetadata);

    if (selectedSession == null) {
      await _sessionRevocationSubscription?.cancel();
      _sessionRevocationSubscription = null;
      _presenceTimer?.cancel();
      _presenceTimer = null;
      _activeSessionReference = null;
      return;
    }

    await preferences.setString(
      'active_login_session_${authUser.uid}',
      selectedSession.id,
    );
    _activeSessionReference = selectedSession.reference;
    await _updateSessionPresence(selectedSession.reference, isOnline: true);
    _startSessionHeartbeat(authUser.uid, selectedSession.reference);

    await _sessionRevocationSubscription?.cancel();
    _sessionRevocationSubscription = selectedSession.reference
        .snapshots()
        .listen((snapshot) {
          if (snapshot.data()?['revoked'] == true) {
            _sessionRevocationSubscription?.cancel();
            _sessionRevocationSubscription = null;
            _presenceTimer?.cancel();
            _presenceTimer = null;
            _activeSessionReference = null;
            _auth.signOut();
          }
        });
  }

  void _startSessionHeartbeat(
    String uid,
    DocumentReference<Map<String, dynamic>> sessionReference,
  ) {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_auth.currentUser?.uid != uid) {
        timer.cancel();
        return;
      }
      unawaited(_updateSessionPresence(sessionReference, isOnline: true));
    });
  }

  Future<void> _updateSessionPresence(
    DocumentReference<Map<String, dynamic>> sessionReference, {
    required bool isOnline,
  }) async {
    try {
      await sessionReference.set({
        'is_online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _latestMatchingSession(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
    Map<String, String> localMetadata,
  ) {
    final matching = sessions
        .where(
          (doc) =>
              doc.data()['revoked'] != true &&
              _sameSessionDevice(doc.data(), localMetadata),
        )
        .toList();
    matching.sort((a, b) {
      final aDate = _sessionDate(a.data());
      final bDate = _sessionDate(b.data());
      return bDate.compareTo(aDate);
    });
    return matching.isEmpty ? null : matching.first;
  }

  bool _sameSessionDevice(
    Map<String, dynamic> session,
    Map<String, String> localMetadata,
  ) {
    final sessionDevice = (session['device'] ?? session['device_name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final sessionPlatform = (session['platform'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final localDevice = (localMetadata['device'] ?? '').trim().toLowerCase();
    final localPlatform = (localMetadata['platform'] ?? '')
        .trim()
        .toLowerCase();
    return sessionDevice == localDevice && sessionPlatform == localPlatform;
  }

  DateTime _sessionDate(Map<String, dynamic> data) {
    final value = data['logged_in_at'] ?? data['loggedInAt'];
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse('$value') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<Map<String, String>> _loginMetadata() async {
    var device = 'Tidak tersedia';
    var platform = 'Tidak tersedia';
    var appVersion = 'Tidak tersedia';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = 'ORVIX App v${packageInfo.version}';
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final web = await deviceInfo.webBrowserInfo;
        device = web.browserName.name;
        platform = web.platform ?? 'Web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await deviceInfo.androidInfo;
        device = '${android.manufacturer} ${android.model}'.trim();
        platform = 'Android ${android.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await deviceInfo.iosInfo;
        device = ios.name;
        platform = 'iOS ${ios.systemVersion}';
      } else {
        platform = defaultTargetPlatform.name;
      }
    } catch (_) {}

    var ipAddress = 'Tidak tersedia';
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        ipAddress = body['ip']?.toString() ?? ipAddress;
      }
    } catch (_) {}

    return {
      'device': device,
      'device_name': device,
      'platform': platform,
      'browser': '$platform / $appVersion',
      'app_version': appVersion,
      'ip_address': ipAddress,
    };
  }

  // 4. LOGOUT
  Future<void> logout() async {
    await _sessionRevocationSubscription?.cancel();
    _sessionRevocationSubscription = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    final user = currentUser;
    final preferences = await SharedPreferences.getInstance();
    final sessionId = user == null
        ? null
        : preferences.getString('active_login_session_${user.uid}');
    final sessionReference =
        _activeSessionReference ??
        (user == null || sessionId == null
            ? null
            : _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('login_history')
                  .doc(sessionId));
    if (sessionReference != null) {
      await _updateSessionPresence(sessionReference, isOnline: false);
    }
    _activeSessionReference = null;
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
