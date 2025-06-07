import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

class CustomOverlayNotification {
  static void show(BuildContext context, String message, {bool isSuccess = true}) {
    // Buat OverlayEntry
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, // Di bawah status bar
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSuccess ? AppColors.success : AppColors.error, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tampilkan Overlay
    Overlay.of(context).insert(overlayEntry);

    // Hapus setelah beberapa detik
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
