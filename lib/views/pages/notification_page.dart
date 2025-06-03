import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';

class NotificationPage extends StatelessWidget {
  final FirestoreService firestoreService;
  final AuthService authService;
  const NotificationPage({super.key, required this.firestoreService, required this.authService});

  @override
  Widget build(BuildContext context) {
    // Ganti dengan implementasi UI Anda yang sudah ada
    // Untuk sekarang, hanya placeholder
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(color: AppColors.textPrimaryDark)),
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Halaman Notifikasi Akan Datang'),
      ),
    );
  }
}

