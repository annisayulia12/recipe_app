import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';

class RecipeHeader extends StatelessWidget {
  final RecipeModel recipe;
  const RecipeHeader({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    const metaTextStyle = TextStyle(fontSize: 12, color: AppColors.greyMedium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
          Image.network(
            recipe.imageUrl!,
            width: double.infinity, height: 250, fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 250, color: AppColors.greyLight, child: const Center(child: CircularProgressIndicator())),
            errorBuilder: (context, error, stack) => Container(height: 250, color: AppColors.greyLight, child: const Icon(Icons.broken_image, color: AppColors.greyMedium)),
          )
        else
          Container(width: double.infinity, height: 250, color: AppColors.greyLight, child: const Icon(Icons.restaurant_menu, size: 60)),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recipe.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
              const SizedBox(height: 4),
              Text("Diposting pada ${recipe.createdAt.toDate().toString().substring(0, 10)}", style: metaTextStyle),
              if (recipe.updatedAt != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 4.0),
                   child: Text("Diperbarui pada ${recipe.updatedAt!.toDate().toString().substring(0, 10)}", style: metaTextStyle.copyWith(fontStyle: FontStyle.italic)),
                 ),
            ],
          ),
        ),
      ],
    );
  }
}