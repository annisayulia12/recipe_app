// lib/services/recipe_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/main.dart';
import 'package:recipein_app/services/storage_service.dart'; // Import StorageService

const String recipeDataContainerDocId = 'all_recipes_container';

class RecipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService(); // Buat instance StorageService

  CollectionReference<RecipeModel> _recipesRef() {
    return _db.collection('artifacts').doc(appId).collection('data')
      .doc(recipeDataContainerDocId).collection('recipes')
      .withConverter<RecipeModel>(
        fromFirestore: (s, _) => RecipeModel.fromFirestore(s),
        toFirestore: (r, _) => r.toJson(),
      );
  }

  Future<DocumentReference<RecipeModel>> addRecipe(RecipeModel recipe) async {
    try {
      return await _recipesRef().add(recipe);
    } catch (e) {
      print("Error adding recipe: $e");
      throw Exception("Gagal menambah resep.");
    }
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    try {
      await _recipesRef().doc(recipe.id).update(recipe.toJson());
    } catch (e) {
      print("Error updating recipe: $e");
      throw Exception("Gagal memperbarui resep.");
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      // Ambil data resep dulu untuk mendapatkan URL gambarnya
      final recipe = await getRecipe(recipeId);
      if (recipe != null && recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
        // Hapus gambar dari Storage
        await _storageService.deleteFile(recipe.imageUrl!);
      }
      
      // Hapus dokumen resep dari Firestore
      await _recipesRef().doc(recipeId).delete();

    } catch (e) {
      print("Error deleting recipe: $e");
      throw Exception("Gagal menghapus resep.");
    }
  }

  Future<RecipeModel?> getRecipe(String recipeId) async {
    try {
      final snapshot = await _recipesRef().doc(recipeId).get();
      return snapshot.data();
    } catch (e) {
      print("Error getting recipe: $e");
      return null;
    }
  }

  Stream<List<RecipeModel>> getPublicRecipes({int limit = 20}) {
    return _recipesRef().where('isPublic', isEqualTo: true)
      .orderBy('createdAt', descending: true).limit(limit).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<RecipeModel>> getUserRecipes(String userId) {
    return _recipesRef().where('ownerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true).snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}