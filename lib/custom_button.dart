import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF2A7C76), // Warna default jika tidak dispesifikkan
        minimumSize: const Size(double.infinity, 50), // Tombol full width
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
