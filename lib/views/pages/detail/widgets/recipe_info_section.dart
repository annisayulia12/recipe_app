import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';

class RecipeInfoSection extends StatelessWidget {
  final RecipeModel recipe;
  const RecipeInfoSection({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    const headingStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark);
    const bodyTextStyle = TextStyle(fontSize: 14, color: AppColors.textSecondaryDark, height: 1.5);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
            const Text('Deskripsi', style: headingStyle),
            const SizedBox(height: 8),
            Text(recipe.description!, style: bodyTextStyle),
            const Divider(height: 40),
          ],

          const Text('Bahan-bahan', style: headingStyle),
          const SizedBox(height: 8),
          if (recipe.ingredients.isEmpty)
            const Text("Tidak ada bahan yang dicantumkan.", style: bodyTextStyle)
          else
            ...recipe.ingredients.map((val) => Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text('• $val', style: bodyTextStyle))),
          
          const SizedBox(height: 24),

          const Text('Langkah-langkah', style: headingStyle),
          const SizedBox(height: 8),
          if (recipe.steps.isEmpty)
            const Text("Tidak ada langkah-langkah yang dicantumkan.", style: bodyTextStyle)
          else
            ...recipe.steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key + 1}. ', style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(entry.value, style: bodyTextStyle)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
