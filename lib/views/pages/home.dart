// lib/views/pages/home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- IMPORT PROVIDER
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/providers/user_profile_provider.dart'; // <-- IMPORT PROVIDER KITA
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
    required this.interactionService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<RecipeModel>> _publicRecipesStream;

  @override
  void initState() {
    super.initState();
    _publicRecipesStream = widget.recipeService.getPublicRecipes(limit: 20);

    // --- BARU ---
    // Panggil data profil jika belum ada saat halaman ini dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = widget.authService.getCurrentUser();
      final provider = Provider.of<UserProfileProvider>(context, listen: false);
      if (user != null && provider.userProfile == null) {
        provider.fetchUserProfile(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- DIUBAH ---
    // Kita gunakan Consumer untuk mendapatkan data profil pengguna
    return Consumer<UserProfileProvider>(
      builder: (context, userProvider, child) {
        // Ambil nama pengguna, berikan nilai default jika null
        final userName = userProvider.userProfile?.displayName.split(' ').first ?? 'Pengguna';

        return Scaffold(
          appBar: AppBar(
            // --- DIUBAH ---
            // AppBar sekarang menampilkan foto profil yang reaktif
            title: Image.asset('assets/images/logo.png', height: 30),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.greyLight,
                  backgroundImage: (userProvider.userProfile?.photoUrl != null &&
                          userProvider.userProfile!.photoUrl!.isNotEmpty)
                      ? NetworkImage(userProvider.userProfile!.photoUrl!)
                      : const AssetImage('assets/images/profile_placeholder.png')
                          as ImageProvider,
                ),
              ),
            ],
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
                // --- DIUBAH ---
                // Teks sapaan sekarang menampilkan nama pengguna
                Text(
                  'Halo, $userName!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jelajahi Resep Terbaru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  // ... (TextField tidak berubah)
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
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<RecipeModel>>(
                    stream: _publicRecipesStream,
                    builder: (context, snapshot) {
                      // ... (StreamBuilder dan isinya tidak berubah)
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
      },
    );
  }
}