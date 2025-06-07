import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

// Ini bukan widget, tapi fungsi helper yang menampilkan dialog kustom kita.
Future<bool?> showCustomConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content, // Gunakan Widget agar bisa memakai RichText
  String confirmText = 'Keluar',
  String cancelText = 'Batal',
  Color confirmButtonColor = AppColors.primaryGreen,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 40),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: content,
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
      actions: <Widget>[
        SizedBox(
          width: 110, // Beri sedikit ruang lebih
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false), // Mengembalikan false
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(cancelText),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Mengembalikan true
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmButtonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}
