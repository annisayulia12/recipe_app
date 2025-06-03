import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textTitle,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSubtitle,
  );

  static final textTheme = TextTheme(
    titleMedium: title,
    bodyMedium: subtitle,
  );
}
