import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:app_pt_ewf/Views/Onbording/splash_screen.dart';
import 'package:app_pt_ewf/Views/Auth/reset_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan opsi platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _handledResetCode;

  @override
  void initState() {
    super.initState();
    _listenForPasswordResetLinks();
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
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orvix App',
      navigatorKey: _navigatorKey,
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(), // Memanggil SplashScreen sebagai halaman awal
    );
  }
}
