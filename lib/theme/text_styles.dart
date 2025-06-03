import 'package:flutter/material.dart';
// Menggunakan AppColors dari constants
import 'package:recipein_app/constants/app_colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDark, // Menggunakan AppColors dari constants
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondaryDark, // Menggunakan AppColors dari constants
  );

  // Anda bisa memperluas TextTheme ini sesuai kebutuhan
  static final TextTheme textTheme = TextTheme(
    titleLarge: title.copyWith(fontSize: 22, fontWeight: FontWeight.bold), // Contoh titleLarge
    titleMedium: title, // titleMedium sudah ada
    bodyLarge: subtitle.copyWith(fontSize: 16), // Contoh bodyLarge
    bodyMedium: subtitle, // bodyMedium sudah ada
    labelLarge: const TextStyle( // Untuk tombol misalnya
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight
    ),
    displaySmall: TextStyle(fontSize: 12, color: AppColors.greyMedium) // Contoh untuk teks meta
  );
}
