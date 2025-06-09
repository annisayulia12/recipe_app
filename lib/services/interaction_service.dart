// lib/services/interaction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/notification_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/main.dart';

class InteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService;
  final RecipeService _recipeService;

  InteractionService({
    required NotificationService notificationService,
    required RecipeService recipeService,
  })  : _notificationService = notificationService,
        _recipeService = recipeService;

  // --- Path Helpers ---
  CollectionReference _recipesRef() => _db
      .collection('artifacts')
      .doc(appId)
      .collection('data')
      .doc('all_recipes_container')
      .collection('recipes');

  DocumentReference _recipeLikeRef(String recipeId, String userId) =>
      _recipesRef().doc(recipeId).collection('likes').doc(userId);

  DocumentReference _userBookmarkRef(String userId, String recipeId) => _db
      .collection('artifacts')
      .doc(appId)
      .collection('users')
      .doc(userId)
      .collection('bookmarks')
      .doc(recipeId);
  
  // Helper untuk koleksi bookmark pengguna
  CollectionReference _userBookmarksCollection(String userId) => _db
      .collection('artifacts')
      .doc(appId)
      .collection('users')
      .doc(userId)
      .collection('bookmarks');


  CollectionReference<CommentModel> _commentsRef(String recipeId) =>
      _recipesRef()
          .doc(recipeId)
          .collection('comments')
          .withConverter<CommentModel>(
            fromFirestore: (s, _) => CommentModel.fromFirestore(s),
            toFirestore: (c, _) => c.toJson(),
          );

  CollectionReference<ReplyModel> _repliesRef(
    String recipeId,
    String commentId,
  ) =>
      _commentsRef(recipeId).doc(commentId).collection('replies').withConverter<ReplyModel>(
            fromFirestore: (s, _) => ReplyModel.fromFirestore(s),
            toFirestore: (r, _) => r.toJson(),
          );

  // ... (Fungsi like, unlike, bookmark, unbookmark, comment, reply tidak berubah) ...
  // --- Likes (Diperbarui dengan WriteBatch) ---
  Future<void> likeRecipe(RecipeModel recipe, User actor) async {
    final batch = _db.batch();
    batch.set(_recipeLikeRef(recipe.id, actor.uid), {
      'likedAt': Timestamp.now(),
    });
    batch.update(_recipesRef().doc(recipe.id), {
      'likesCount': FieldValue.increment(1),
    });
    await batch.commit();
    await _notificationService.createNotification(
      recipientId: recipe.ownerId,
      actor: actor,
      type: NotificationType.like,
      recipe: recipe,
    );
  }

  Future<void> unlikeRecipe(String recipeId, String userId) async {
    final batch = _db.batch();
    batch.delete(_recipeLikeRef(recipeId, userId));
    batch.update(_recipesRef().doc(recipeId), {
      'likesCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<bool> isRecipeLikedByUser(String recipeId, String userId) async =>
      (await _recipeLikeRef(recipeId, userId).get()).exists;

  // --- Bookmarks (Diperbarui dengan WriteBatch) ---
  Future<void> bookmarkRecipe(RecipeModel recipe, User actor) async {
    final batch = _db.batch();
    batch.set(_userBookmarkRef(actor.uid, recipe.id), {
      'bookmarkedAt': Timestamp.now(),
      'recipeTitle': recipe.title,
      'recipeImageUrl': recipe.imageUrl,
    });
    batch.update(_recipesRef().doc(recipe.id), {
      'bookmarksCount': FieldValue.increment(1),
    });
    await batch.commit();
    await _notificationService.createNotification(
      recipientId: recipe.ownerId,
      actor: actor,
      type: NotificationType.bookmark,
      recipe: recipe,
    );
  }

  Future<void> unbookmarkRecipe(String userId, String recipeId) async {
    final batch = _db.batch();
    batch.delete(_userBookmarkRef(userId, recipeId));
    batch.update(_recipesRef().doc(recipeId), {
      'bookmarksCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<bool> isRecipeBookmarkedByUser(String userId, String recipeId) async =>
      (await _userBookmarkRef(userId, recipeId).get()).exists;

  // --- Comments & Replies (Diperbarui dengan WriteBatch) ---
  Future<void> addComment(
    CommentModel comment,
    RecipeModel recipe,
    User actor,
  ) async {
    final batch = _db.batch();
    final newCommentRef = _commentsRef(comment.recipeId).doc();
    batch.set(newCommentRef, comment);
    batch.update(_recipesRef().doc(comment.recipeId), {
      'commentsCount': FieldValue.increment(1),
    });
    await batch.commit();
    await _notificationService.createNotification(
      recipientId: recipe.ownerId,
      actor: actor,
      type: NotificationType.comment,
      recipe: recipe,
      commentText: comment.text,
    );
  }

  Future<void> addReply(
    ReplyModel reply,
    String recipeId,
    CommentModel parentComment,
    User actor,
  ) async {
    final recipe = await _recipeService.getRecipe(recipeId);
    if (recipe == null) {
      throw Exception("Resep tidak ditemukan saat mencoba membalas.");
    }

    final batch = _db.batch();
    final newReplyRef = _repliesRef(recipeId, parentComment.id).doc();
    batch.set(newReplyRef, reply);
    batch.update(_commentsRef(recipeId).doc(parentComment.id), {
      'repliesCount': FieldValue.increment(1),
    });
    await batch.commit();
    await _notificationService.createNotification(
      recipientId: parentComment.userId,
      actor: actor,
      type: NotificationType.reply,
      recipe: recipe,
      commentText: reply.text,
    );
  }

  Stream<List<CommentModel>> getComments(String recipeId) =>
      _commentsRef(recipeId)
          .orderBy('createdAt')
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());
  Stream<List<ReplyModel>> getReplies(String recipeId, String commentId) =>
      _repliesRef(recipeId, commentId)
          .orderBy('createdAt')
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  /// **IMPLEMENTASI BARU**
  /// Mengambil stream dari daftar resep yang disimpan (di-bookmark) oleh pengguna.
  Stream<List<RecipeModel>> getSavedRecipes(String userId) {
    return _userBookmarksCollection(userId)
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return []; // Jika tidak ada bookmark, kembalikan list kosong
          }
          
          // Ambil semua ID resep dari dokumen bookmark
          final recipeIds = snapshot.docs.map((doc) => doc.id).toList();

          // Panggil RecipeService untuk mengambil detail dari setiap resep
          // Fungsi ini mengasumsikan ada method di RecipeService untuk mengambil
          // beberapa resep berdasarkan ID. Jika belum ada, kita bisa membuatnya.
          // Untuk sekarang, kita akan ambil satu per satu.
          
          final List<RecipeModel> recipes = [];
          for (String recipeId in recipeIds) {
            final recipe = await _recipeService.getRecipe(recipeId);
            if (recipe != null) {
              recipes.add(recipe);
            }
          }
          return recipes;
    });
  }
}