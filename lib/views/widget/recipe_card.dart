import 'package:flutter/material.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/views/pages/detail_card.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/firestore_service.dart'; // Impor FirestoreService

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final FirestoreService firestoreService; // Tambahkan parameter ini

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.firestoreService, // Jadikan parameter wajib
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailCard(
                recipeId: recipe.id,
                firestoreService: firestoreService, // Teruskan firestoreService
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? Image.network(
                        recipe.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 160,
                            width: double.infinity,
                            color: AppColors.greyLight,
                            child: const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 160,
                            width: double.infinity,
                            color: AppColors.greyLight,
                            child: const Icon(Icons.broken_image, color: AppColors.greyMedium, size: 40),
                          );
                        },
                      )
                    : Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: AppColors.greyMedium, size: 50),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: recipe.ownerPhotoUrl != null && recipe.ownerPhotoUrl!.isNotEmpty
                        ? NetworkImage(recipe.ownerPhotoUrl!)
                        : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                    radius: 18,
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'oleh ${recipe.ownerName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                           maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 20, color: AppColors.greyMedium),
                      const SizedBox(width: 4),
                      Text(recipe.likesCount.toString(), style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.greyMedium),
                       const SizedBox(width: 4),
                      Text(recipe.commentsCount.toString(), style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
                      const SizedBox(width: 8),
                      const Icon(Icons.bookmark_border, size: 20, color: AppColors.greyMedium),
                    ],
                  ),
                ],
              ),
               const SizedBox(height: 8),
               Text(
                recipe.description ?? "Tap untuk melihat detail resep...",
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}