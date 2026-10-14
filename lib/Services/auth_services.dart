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

enum StaffRegistrationStatus { verificationSent, completed }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _sessionRevocationSubscription;
  Timer? _presenceTimer;
  DocumentReference<Map<String, dynamic>>? _activeSessionReference;

  User? get currentUser => _auth.currentUser;

  // 1. REGISTRASI KHUSUS STAFF
  Future<StaffRegistrationStatus> registerStaff({
    required String email,
    required String password,
    required String nama,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = nama.trim();
    final normalizedPhone = phone?.trim() ?? '';
    var createdDuringAttempt = false;
    var registrationWriteStarted = false;
    var registrationCommitted = false;

    if (!RegExp(r'^[^@\s/]+@[^@\s/]+\.[^@\s/]+$')
            .hasMatch(normalizedEmail) ||
        normalizedName.isEmpty ||
        normalizedName.length > 120 ||
        normalizedPhone.length > 40 ||
        password.length < 8) {
      throw StateError('Periksa kembali data pendaftaran Anda.');
    }

    final currentAuthUser = _auth.currentUser;
    if (currentAuthUser != null &&
        currentAuthUser.email?.trim().toLowerCase() != normalizedEmail) {
      throw StateError(
        'Keluar dari akun yang sedang aktif sebelum mendaftar dengan email lain.',
      );
    }

    try {
      User? authUser = _auth.currentUser;
      if (authUser == null) {
        try {
          final credential = await _auth.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
          authUser = credential.user;
          createdDuringAttempt = authUser != null;
        } on FirebaseAuthException catch (error) {
          if (error.code != 'email-already-in-use') {
            throw StateError(_handleAuthException(error));
          }
          try {
            final credential = await _auth.signInWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            );
            authUser = credential.user;
          } on FirebaseAuthException catch (signInError) {
            throw StateError(_handleAuthException(signInError));
          }
        }
      }

      if (authUser == null) {
        throw StateError('Akun Firebase tidak berhasil dibuat.');
      }

      await authUser.reload();
      authUser = _auth.currentUser;
      if (authUser == null ||
          authUser.email?.trim().toLowerCase() != normalizedEmail) {
        throw StateError('Email akun tidak cocok dengan email pendaftaran.');
      }

      final existingProfile = await _firestore
          .collection('users')
          .doc(authUser.uid)
          .get();
      if (existingProfile.exists) {
        final existingData = existingProfile.data() ?? <String, dynamic>{};
        if (_isAdmin(existingData)) {
          throw StateError('Akun admin tidak perlu didaftarkan sebagai staff.');
        }
        if (existingData['account_created'] == true) {
          throw StateError(
            'Email ini sudah memiliki akun. Silakan masuk atau gunakan Lupa Password.',
          );
        }
      }

      final invitation = await _getStaffInvitation(normalizedEmail);
      if (!invitation.exists) {
        throw StateError('Email ini belum didaftarkan oleh admin.');
      }
      final invitationData = invitation.data()!;
      if (!_isStaffInvitation(invitationData)) {
        throw StateError('Email ini belum memiliki undangan pendaftaran staff.');
      }
      if ((invitationData['email'] ?? '').toString().trim().toLowerCase() !=
          normalizedEmail) {
        throw StateError('Email undangan tidak cocok dengan email pendaftaran.');
      }
      if (!_isUserActive(invitationData)) {
        throw StateError('Undangan staff ini nonaktif. Hubungi admin.');
      }

      if (!authUser.emailVerified) {
        await authUser.updateDisplayName(normalizedName);
        await authUser.sendEmailVerification();
        return StaffRegistrationStatus.verificationSent;
      }
      await authUser.getIdToken(true);

      final profileReference = _firestore
          .collection('users')
          .doc(authUser.uid);
      final registrationBatch = _firestore.batch();
      registrationBatch.set(profileReference, {
        'user_id': authUser.uid,
        'nama': normalizedName,
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'jenis_kelamin': invitationData['jenis_kelamin'] ?? '',
        'role': 'staff',
        'status': 'active',
        'isActive': true,
        'aktif': true,
        'account_created': true,
        'pending_registration': false,
        if (invitationData['createdAt'] != null)
          'createdAt': invitationData['createdAt'],
        'registeredAt': FieldValue.serverTimestamp(),
      });
      registrationBatch.delete(invitation.reference);
      registrationWriteStarted = true;
      await registrationBatch.commit();
      registrationCommitted = true;

      await _auth.signOut();
      return StaffRegistrationStatus.completed;
    } catch (error) {
      if (createdDuringAttempt &&
          !registrationWriteStarted &&
          !registrationCommitted &&
          _auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (cleanupError) {
          debugPrint(
            'Failed to remove an unregistered Firebase Auth account: '
            '$cleanupError',
          );
        }
      } else if (!registrationCommitted && _auth.currentUser != null) {
        try {
          await _auth.signOut();
        } catch (cleanupError) {
          debugPrint(
            'Failed to sign out after staff registration failed: '
            '$cleanupError',
          );
        }
      }
      if (error is FirebaseAuthException) {
        throw StateError(_handleAuthException(error));
      }
      if (error is FirebaseException && error.code == 'permission-denied') {
        throw StateError(
          'Akses Firestore ditolak. Deploy firestore.rules yang disiapkan untuk alur pendaftaran staff.',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> signInWithRegisteredGoogle({
    required AuthCredential credential,
    required String googleEmail,
    String? passwordForLink,
  }) async {
    final normalizedEmail = googleEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw StateError('Email akun Google tidak tersedia.');
    }

    final users = _firestore.collection('users');
    UserCredential? authResult;
    try {
      UserCredential signInResult;
      try {
        signInResult = await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (error.code != 'account-exists-with-different-credential') {
          throw StateError(_handleAuthException(error));
        }
        if (passwordForLink == null || passwordForLink.isEmpty) {
          throw StateError(
            'Masukkan password akun ini untuk menautkan Google pada login pertama.',
          );
        }
        try {
          final emailPasswordAccount = await _auth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: passwordForLink,
          );
          final emailPasswordUser = emailPasswordAccount.user;
          if (emailPasswordUser == null ||
              emailPasswordUser.email?.trim().toLowerCase() !=
                  normalizedEmail) {
            throw StateError('Email dan password akun tidak cocok.');
          }
          signInResult = await emailPasswordUser.linkWithCredential(
            credential,
          );
        } on FirebaseAuthException catch (linkError) {
          throw StateError(_handleAuthException(linkError));
        }
      }
      authResult = signInResult;
      final authUser = signInResult.user;
      if (authUser == null ||
          authUser.email?.trim().toLowerCase() != normalizedEmail) {
        throw StateError('Email akun Google tidak cocok.');
      }

      final userReference = users.doc(authUser.uid);
      final existingProfile = await userReference.get();
      if (!existingProfile.exists) {
        throw StateError(
          'Akun ini belum dibuat. Silakan daftar akun terlebih dahulu.',
        );
      }

      final profileData = existingProfile.data() ?? <String, dynamic>{};
      final profileEmail =
          (profileData['email'] ??
                  profileData['user_email'] ??
                  profileData['email_address'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
      if (profileEmail != normalizedEmail) {
        throw StateError('Email akun tidak cocok dengan profil.');
      }
      if (!_isAdmin(profileData) &&
          (profileData['account_created'] ?? false) != true) {
        throw StateError(
          'Akun belum selesai dibuat. Silakan daftar akun terlebih dahulu.',
        );
      }
      if (!_isUserActive(profileData)) {
        throw StateError('Akun Anda nonaktif. Hubungi admin.');
      }

      final profile = UserModel.fromMap(profileData);
      await recordLogin(user: profile);
      return profile;
    } catch (_) {
      if (authResult?.additionalUserInfo?.isNewUser == true) {
        try {
          await authResult?.user?.delete();
        } catch (cleanupError) {
          debugPrint(
            'Failed to delete an unregistered Google authentication user: '
            '$cleanupError',
          );
        }
      }
      if (_auth.currentUser != null) await _auth.signOut();
      rethrow;
    }
  }

  bool _isUserActive(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'active').toString().trim().toLowerCase();
    return data['isActive'] != false &&
        data['aktif'] != false &&
        status != 'inactive' &&
        status != 'nonaktif';
  }

  bool _isAdmin(Map<String, dynamic> data) =>
      (data['role'] ?? '').toString().trim().toLowerCase() == 'admin';

  bool _isStaffInvitation(Map<String, dynamic> data) =>
      (data['role'] ?? '').toString().trim().toLowerCase() == 'staff' &&
      data['account_created'] != true &&
      data['pending_registration'] == true;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getStaffInvitation(
    String email,
  ) => _firestore.collection('users').doc(email).get();

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

      final authUser = userCred.user!;
      final userDoc = await _firestore
          .collection('users')
          .doc(authUser.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw StateError(
          'Akun ini belum dibuat. Silakan daftar akun terlebih dahulu.',
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isAdmin = _isAdmin(userData);
      if (!isAdmin && !authUser.emailVerified) {
        await _auth.signOut();
        throw StateError(
          'Verifikasi email dari tautan yang dikirim sebelum masuk.',
        );
      }
      if (!isAdmin && (userData['account_created'] ?? false) != true) {
        await _auth.signOut();
        throw StateError(
          'Akun belum selesai dibuat. Silakan daftar akun terlebih dahulu.',
        );
      }
      if (!_isUserActive(userData)) {
        await _auth.signOut();
        throw StateError('Akun Anda nonaktif. Hubungi admin.');
      }

      await _removeLegacyPasswordFields(authUser.uid);
      final user = UserModel.fromMap(userData);
      await recordLogin(user: user);
      return user;
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
    } catch (error, stackTrace) {
      debugPrint('Failed to record login history: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
        return 'Email ini sudah memiliki akun. Silakan masuk atau gunakan '
            'Lupa Password.';
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
