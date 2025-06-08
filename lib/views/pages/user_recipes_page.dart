import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/views/widget/recipe_card.dart';

class UserRecipesPage extends StatefulWidget {
  final RecipeService recipeService;
  final InteractionService interactionService;
  final AuthService authService;

  const UserRecipesPage({
    super.key, 
    required this.recipeService, 
    required this.interactionService, 
    required this.authService
  });

  @override
  State<UserRecipesPage> createState() => _UserRecipesPageState();
}

class _UserRecipesPageState extends State<UserRecipesPage> {
  String? _currentUserId;
  // State variable untuk menyimpan stream agar tidak dibuat ulang
  late final Stream<List<RecipeModel>> _userRecipesStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.authService.getCurrentUser()?.uid;
    // Inisialisasi stream HANYA SEKALI di sini
    if (_currentUserId != null) {
      _userRecipesStream = widget.recipeService.getUserRecipes(_currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resep Saya')),
        body: const Center(child: Text('Anda harus login untuk melihat resep Anda.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Saya', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: AppColors.offWhite,
      body: StreamBuilder<List<RecipeModel>>(
        // Gunakan stream yang sudah disimpan di state
        stream: _userRecipesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Anda belum memiliki resep.\nTekan tombol `+` untuk mulai membagikan resep pertama Anda!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.greyMedium),
                ),
              ),
            );
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                recipeService: widget.recipeService,
                interactionService: widget.interactionService,
                authService: widget.authService,
              );
            },
          );
        },
      ),
    );
  }
}
