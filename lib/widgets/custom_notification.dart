import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

// Fungsi helper untuk menampilkan toast kustom
void showCustomToast(BuildContext context, String message, {bool isSuccess = true}) {
  final snackBar = SnackBar(
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA), // Latar belakang hijau/merah muda
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSuccess ? AppColors.success : AppColors.error, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? AppColors.primaryGreen : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.transparent, // Buat latar belakang SnackBar transparan
    elevation: 0,
    behavior: SnackBarBehavior.floating, // Buat SnackBar mengambang
    margin: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20), // Atur posisi dari atas
    duration: const Duration(seconds: 2), // Durasi notifikasi
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
