// lib/views/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';

class ProfilePage extends StatelessWidget {
  final AuthService authService;
  final UserService userService;
  
  const ProfilePage({
    super.key, 
    required this.authService, 
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    // Ganti dengan implementasi UI Anda yang sudah ada
    // Untuk sekarang, hanya placeholder
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(color: AppColors.textPrimaryDark)),
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryOrange),
            onPressed: () async {
              await authService.signOut();
              // AuthGate akan menangani navigasi ke halaman login
            },
          )
        ],
      ),
      body: Center(
        child: Text('Halaman Profil Akan Datang. Pengguna: ${authService.getCurrentUser()?.email ?? "Tidak ada"}'),
      ),
    );
  }
}