import 'package:flutter/material.dart';
// Import file splash screen yang sudah dipisah tadi
import 'package:app_pt_ewf/views/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orvix App',
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(), // Memanggil SplashScreen sebagai halaman awal
    );
  }
}
