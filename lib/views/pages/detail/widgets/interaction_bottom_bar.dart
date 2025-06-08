import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';

class InteractionBottomBar extends StatelessWidget {
  final RecipeModel recipe;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLikeTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onCopyTap;
  final VoidCallback onShareTap;

  const InteractionBottomBar({
    super.key,
    required this.recipe,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLikeTap,
    required this.onBookmarkTap,
    required this.onCopyTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.white,
      elevation: 10.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onBookmarkTap,
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? AppColors.primaryOrange : AppColors.textPrimaryDark,
                size: 22,
              ),
              label: Text(
                "${recipe.bookmarksCount} disimpan",
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            Row(
              children: [
                _buildSmallInteractionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.error : AppColors.greyDark,
                  onTap: onLikeTap,
                ),
                _buildSmallInteractionButton(
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.greyDark,
                  onTap: () => CustomOverlayNotification.show(context, 'Fitur komentar akan segera hadir!', isSuccess: false),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'copy') onCopyTap();
                    else if (value == 'share') onShareTap();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 20), SizedBox(width: 8), Text('Salin Tautan')])),
                    const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 20), SizedBox(width: 8), Text('Bagikan')])),
                  ],
                  icon: const Icon(Icons.send_outlined, color: AppColors.greyDark, size: 24),
                  tooltip: "Bagikan",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInteractionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}