// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk User?
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart'; // Impor FirestoreService Anda
import 'package:recipein_app/login_register_toggle_page.dart'; // Halaman login/register Anda
import 'package:recipein_app/views/widget/button_nav_bar.dart';  // Impor ButtonNavBar Anda

class AuthGate extends StatelessWidget {
  // Gunakan tipe yang sebenarnya, bukan dynamic
  final AuthService authService;
  final FirestoreService firestoreService;

  // Constructor yang menerima kedua layanan dengan tipe yang benar
  const AuthGate({
    super.key,
    required this.authService,
    required this.firestoreService,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ButtonNavBar(
            authService: authService,
            firestoreService: firestoreService,
          );
        }
        return LoginRegisterTogglePage(
          authService: authService,
        );
      },
    );
  }
}
