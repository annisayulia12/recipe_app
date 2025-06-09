// lib/views/pages/saved_recipes_page.dart

import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/recipe_model.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/views/widget/recipe_card.dart';

class SavedRecipesPage extends StatelessWidget {
  final AuthService authService;
  final InteractionService interactionService;
  final RecipeService recipeService;

  const SavedRecipesPage({
    super.key,
    required this.authService,
    required this.interactionService,
    required this.recipeService,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.getCurrentUser();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text(
          'Resep Disimpan',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: currentUser == null
          ? _buildEmptyState('Anda harus login untuk melihat resep yang disimpan.')
          : StreamBuilder<List<RecipeModel>>(
              stream: interactionService.getSavedRecipes(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryOrange),
                  );
                }
                if (snapshot.hasError) {
                  return _buildEmptyState('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState('Anda belum menyimpan resep apapun.');
                }

                final savedRecipes = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = savedRecipes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: RecipeCard(
                        recipe: recipe,
                        recipeService: recipeService,
                        interactionService: interactionService,
                        authService: authService,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.greyMedium),
        ),
      ),
    );
  }
}