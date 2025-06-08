import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/notification_service.dart';
import 'package:recipein_app/main.dart';

class InteractionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService; // Dependensi ke NotificationService

  InteractionService({required NotificationService notificationService}) 
    : _notificationService = notificationService;

  // --- Path Helpers ---
  CollectionReference _recipesRef() => _db.collection('artifacts').doc(appId).collection('data').doc('all_recipes_container').collection('recipes');
  DocumentReference _recipeLikeRef(String recipeId, String userId) => _recipesRef().doc(recipeId).collection('likes').doc(userId);
  DocumentReference _userBookmarkRef(String userId, String recipeId) => _db.collection('artifacts').doc(appId).collection('users').doc(userId).collection('bookmarks').doc(recipeId);
  CollectionReference<CommentModel> _commentsRef(String recipeId) => _recipesRef().doc(recipeId).collection('comments').withConverter<CommentModel>(fromFirestore: (s, _) => CommentModel.fromFirestore(s), toFirestore: (c, _) => c.toJson());

  // --- Likes ---
  Future<void> likeRecipe(RecipeModel recipe, User actor) async {
    await _recipeLikeRef(recipe.id, actor.uid).set({'likedAt': Timestamp.now()});
    await _recipesRef().doc(recipe.id).update({'likesCount': FieldValue.increment(1)});
    await _notificationService.createNotification(recipientId: recipe.ownerId, actor: actor, type: NotificationType.like, recipe: recipe);
  }

  Future<void> unlikeRecipe(String recipeId, String userId) async {
    await _recipeLikeRef(recipeId, userId).delete();
    await _recipesRef().doc(recipeId).update({'likesCount': FieldValue.increment(-1)});
  }
  
  Future<bool> isRecipeLikedByUser(String recipeId, String userId) async => (await _recipeLikeRef(recipeId, userId).get()).exists;

  // --- Bookmarks ---
  Future<void> bookmarkRecipe(RecipeModel recipe, User actor) async {
    await _userBookmarkRef(actor.uid, recipe.id).set({'bookmarkedAt': Timestamp.now(), 'recipeTitle': recipe.title, 'recipeImageUrl': recipe.imageUrl});
    await _recipesRef().doc(recipe.id).update({'bookmarksCount': FieldValue.increment(1)});
    await _notificationService.createNotification(recipientId: recipe.ownerId, actor: actor, type: NotificationType.bookmark, recipe: recipe);
  }

  Future<void> unbookmarkRecipe(String userId, String recipeId) async {
    await _userBookmarkRef(userId, recipeId).delete();
    await _recipesRef().doc(recipeId).update({'bookmarksCount': FieldValue.increment(-1)});
  }
  
  Future<bool> isRecipeBookmarkedByUser(String userId, String recipeId) async => (await _userBookmarkRef(userId, recipeId).get()).exists;

  // --- Comments ---
  Future<void> addComment(CommentModel comment, RecipeModel recipe, User actor) async {
    await _commentsRef(comment.recipeId).add(comment);
    await _recipesRef().doc(comment.recipeId).update({'commentsCount': FieldValue.increment(1)});
    await _notificationService.createNotification(recipientId: recipe.ownerId, actor: actor, type: NotificationType.comment, recipe: recipe, commentText: comment.text);
  }

  Stream<List<CommentModel>> getComments(String recipeId) => _commentsRef(recipeId).orderBy('createdAt', descending: false).snapshots().map((s) => s.docs.map((d) => d.data()).toList());
}
