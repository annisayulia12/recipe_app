import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

class RecipeActionsMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecipeActionsMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.greyMedium, // Sesuaikan warna ikon
        size: 28,
      ),
      onSelected: (String result) {
        if (result == 'edit') {
          onEdit();
        } else if (result == 'delete') {
          onDelete();
        }
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.textPrimaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Postingan',
                    style: TextStyle(color: AppColors.textPrimaryDark),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Hapus Postingan',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
      offset: const Offset(0, 40), // Adjust the offset to position the menu
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
    );
  }
}
