import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:app_pt_ewf/Views/Onbording/splash_screen.dart';
import 'package:app_pt_ewf/Views/Onbording/onboarding_screen.dart';
import 'package:app_pt_ewf/Views/Auth/reset_password.dart';
import 'package:app_pt_ewf/Services/auth_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // Inisialisasi Firebase dengan opsi platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  AuthService? _authService;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;
  Timer? _inactivityTimer;
  DateTime? _lastActivityAt;
  DateTime? _lastPersistedActivityAt;
  String? _trackedAdminUid;
  bool _isAdminSession = false;
  bool _isLoggingOutForInactivity = false;
  bool _hasReceivedInitialAuthState = false;
  String? _handledResetCode;

  static const _adminInactivityTimeout = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForPasswordResetLinks();
    _startAuthSessionTracking();
  }

  AuthService get _sessionAuthService => _authService ??= AuthService();

  void _startAuthSessionTracking() {
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _updateSessionForUser,
      );
    } catch (_) {}
  }

  Future<void> _updateSessionForUser(User? user) async {
    _stopInactivityTracking();
    if (user == null) {
      final previousUid = _trackedAdminUid;
      _trackedAdminUid = null;
      if (previousUid != null) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_adminActivityKey(previousUid));
      }
      final wasInitialized = _hasReceivedInitialAuthState;
      _hasReceivedInitialAuthState = true;
      if (wasInitialized && mounted) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (_) => false,
        );
      }
      return;
    }
    _hasReceivedInitialAuthState = true;

    final profile = await _sessionAuthService.getCurrentUserData();
    if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
      return;
    }

    _isAdminSession = profile?.role.trim().toLowerCase() == 'admin';
    if (_isAdminSession) {
      _trackedAdminUid = user.uid;
      final preferences = await SharedPreferences.getInstance();
      final savedActivity = preferences.getInt(_adminActivityKey(user.uid));
      if (savedActivity != null &&
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(savedActivity),
              ) >=
              _adminInactivityTimeout) {
        await preferences.remove(_adminActivityKey(user.uid));
        await _sessionAuthService.logout();
        return;
      }
      _recordActivity(persistImmediately: true);
    } else {
      _trackedAdminUid = null;
    }

    await _sessionAuthService.monitorCurrentSession();
  }

  String _adminActivityKey(String uid) => 'admin_last_activity_$uid';

  void _recordActivity({bool persistImmediately = false}) {
    if (!_isAdminSession || _isLoggingOutForInactivity) return;

    final now = DateTime.now();
    _lastActivityAt = now;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_adminInactivityTimeout, _logoutForInactivity);

    final uid = _trackedAdminUid;
    final lastPersisted = _lastPersistedActivityAt;
    if (uid != null &&
        (persistImmediately ||
            lastPersisted == null ||
            now.difference(lastPersisted) >= const Duration(seconds: 10))) {
      _lastPersistedActivityAt = now;
      unawaited(_persistAdminActivity(uid, now));
    }
  }

  Future<void> _persistAdminActivity(String uid, DateTime activity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _adminActivityKey(uid),
      activity.millisecondsSinceEpoch,
    );
  }

  void _stopInactivityTracking() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _lastActivityAt = null;
    _isAdminSession = false;
  }

  Future<void> _logoutForInactivity() async {
    if (!_isAdminSession || _isLoggingOutForInactivity) return;

    _isLoggingOutForInactivity = true;
    _stopInactivityTracking();
    await _sessionAuthService.logout();

    if (!mounted) return;
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
    _isLoggingOutForInactivity = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isAdminSession) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(_sessionAuthService.monitorCurrentSession());
      final lastActivity = _lastActivityAt;
      if (lastActivity != null &&
          DateTime.now().difference(lastActivity) >= _adminInactivityTimeout) {
        _logoutForInactivity();
      } else {
        _scheduleRemainingInactivityTimeout();
      }
    }
  }

  void _scheduleRemainingInactivityTimeout() {
    final lastActivity = _lastActivityAt;
    if (lastActivity == null) {
      _recordActivity(persistImmediately: true);
      return;
    }
    final remaining =
        _adminInactivityTimeout - DateTime.now().difference(lastActivity);
    if (remaining <= Duration.zero) {
      unawaited(_logoutForInactivity());
      return;
    }
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(remaining, _logoutForInactivity);
  }

  Future<void> _listenForPasswordResetLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handlePasswordResetLink(initialUri);
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handlePasswordResetLink,
    );
  }

  void _handlePasswordResetLink(Uri uri) {
    final code = _findResetCode(uri);
    if (code == null || code.isEmpty || code == _handledResetCode) return;

    _handledResetCode = code;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(oobCode: code)),
      );
    });
  }

  String? _findResetCode(Uri uri) {
    if (uri.host == 'reset-password' &&
        uri.queryParameters['mode'] == 'resetPassword') {
      return uri.queryParameters['oobCode'];
    }

    if (uri.queryParameters['mode'] == 'resetPassword') {
      return uri.queryParameters['oobCode'];
    }

    final continueUrl = uri.queryParameters['continueUrl'];
    if (continueUrl == null || continueUrl.isEmpty) return null;

    final nestedUri = Uri.tryParse(Uri.decodeComponent(continueUrl));
    return nestedUri == null ? null : _findResetCode(nestedUri);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _inactivityTimer?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, _) {
        _recordActivity();
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: (_) => _recordActivity(),
        onPointerMove: (_) => _recordActivity(),
        onPointerSignal: (_) => _recordActivity(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Orvix App',
          navigatorKey: _navigatorKey,
          theme: ThemeData(useMaterial3: true),
          home:
              const SplashScreen(), // Memanggil SplashScreen sebagai halaman awal
        ),
      ),
    );
  }
}
