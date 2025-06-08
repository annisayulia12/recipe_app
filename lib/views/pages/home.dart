import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/views/widget/recipe_card.dart';

class HomePage extends StatefulWidget {
  final RecipeService recipeService;
  final AuthService authService;
  final InteractionService interactionService;

  const HomePage({
    super.key, 
    required this.recipeService, 
    required this.authService, 
    required this.interactionService
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  // State variable untuk menyimpan stream agar tidak dibuat ulang
  late final Stream<List<RecipeModel>> _publicRecipesStream;

  @override
  void initState() {
    super.initState();
    // Inisialisasi stream HANYA SEKALI di sini
    _publicRecipesStream = widget.recipeService.getPublicRecipes(limit: 20);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 30),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 1,
      ),
      backgroundColor: AppColors.offWhite,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jelajahi Resep Terbaru',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari resep masakan...',
                prefixIcon: const Icon(Icons.search_sharp, color: AppColors.greyMedium),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.greyLight, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                ),
              ),
              onChanged: (value) {
                // TODO: Implementasi logika search
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<RecipeModel>>(
                // Gunakan stream yang sudah disimpan di state
                stream: _publicRecipesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Oops! Terjadi kesalahan: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada resep publik yang tersedia.\nJadilah yang pertama membagikan resepmu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.greyMedium),
                      ),
                    );
                  }
                  final recipes = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
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
            ),
          ],
        ),
      ),
    );
  }
}