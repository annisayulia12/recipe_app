import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/views/widget/recipe_card.dart';

class UserRecipesPage extends StatefulWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const UserRecipesPage({
    super.key,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<UserRecipesPage> createState() => _UserRecipesPageState();
}

class _UserRecipesPageState extends State<UserRecipesPage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.authService.getCurrentUser()?.uid;
    print("UserRecipesPage: initState, currentUserId: $_currentUserId");
  }

  @override
  Widget build(BuildContext context) {
    print("UserRecipesPage: build() called, currentUserId: $_currentUserId");
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resep Saya', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.white,
          elevation: 1,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Anda harus login untuk melihat resep Anda.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Saya', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
      ),
      backgroundColor: AppColors.offWhite,
      body: StreamBuilder<List<RecipeModel>>(
        stream: widget.firestoreService.getUserRecipes(_currentUserId!),
        builder: (context, snapshot) {
          print("UserRecipesPage StreamBuilder: ConnectionState: ${snapshot.connectionState}");
          if (snapshot.hasError) {
            print("UserRecipesPage StreamBuilder: Error: ${snapshot.error}");
            print("UserRecipesPage StreamBuilder: StackTrace: ${snapshot.stackTrace}");
          }
          if (snapshot.hasData) {
            print("UserRecipesPage StreamBuilder: HasData, count: ${snapshot.data!.length}");
          } else {
            print("UserRecipesPage StreamBuilder: NoData");
          }

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
                  'Anda belum memiliki resep.\nYuk, mulai bagikan resep pertama Anda!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.greyMedium),
                ),
              ),
            );
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                firestoreService: widget.firestoreService,
              );
            },
          );
        },
      ),
    );
  }
}
