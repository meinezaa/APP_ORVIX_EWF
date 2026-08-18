import 'package:flutter/material.dart';
import '../Login/login.dart'; // Memanggil file login.dart yang ada di folder sebelah

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginView()),
            );
          },
          child: const Text('Masuk / Ke Halaman Login'),
        ),
      ),
    );
  }
}
