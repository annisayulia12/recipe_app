import 'package:flutter/material.dart';
import 'package:recipein_app/views/widget/button_nav_bar.dart';
import 'package:recipein_app/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RecipeIn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentOrange),
      ),
      home: const ButtonNavBar(),
    );
  }
}
