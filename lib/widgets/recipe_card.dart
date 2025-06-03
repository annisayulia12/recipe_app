import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const RecipeCard({super.key, required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(imagePath),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text("Bahan-bahan read more", style: AppTextStyles.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
