// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/main.dart'; // Impor main.dart untuk mengakses appId global

const String recipeDataContainerDocId = 'all_recipes_container';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<RecipeModel> _recipesRef() {
    return _db
        .collection('artifacts')
        .doc(appId)
        .collection('data')
        .doc(recipeDataContainerDocId)
        .collection('recipes')
        .withConverter<RecipeModel>(
          fromFirestore: (snapshots, _) {
            // DEBUG: Coba print data mentah sebelum konversi
            // print('Recipe fromFirestore raw data: ${snapshots.data()} for doc ID: ${snapshots.id}');
            try {
              return RecipeModel.fromFirestore(snapshots);
            } catch (e) {
              print('Error in RecipeModel.fromFirestore for doc ID ${snapshots.id}: $e');
              // Melempar error akan menghentikan stream, atau Anda bisa return objek default/null
              // tergantung bagaimana Anda ingin menangani data yang rusak.
              // Untuk debugging, melempar error lebih baik agar terlihat.
              throw Exception('Failed to parse recipe data for doc ${snapshots.id}: $e');
            }
          },
          toFirestore: (recipe, _) => recipe.toJson(),
        );
  }

  // ... (Metode _commentsRef, _repliesRef, _userProfileDocRef, _recipeLikeRef, _userBookmarkRef tetap sama) ...
  CollectionReference<CommentModel> _commentsRef(String recipeId) {
    return _recipesRef()
        .doc(recipeId)
        .collection('comments')
        .withConverter<CommentModel>(
          fromFirestore: (snapshots, _) => CommentModel.fromFirestore(snapshots),
          toFirestore: (comment, _) => comment.toJson(),
        );
  }

  CollectionReference<ReplyModel> _repliesRef(String recipeId, String commentId) {
    return _commentsRef(recipeId)
        .doc(commentId)
        .collection('replies')
        .withConverter<ReplyModel>(
          fromFirestore: (snapshots, _) => ReplyModel.fromFirestore(snapshots),
          toFirestore: (reply, _) => reply.toJson(),
        );
  }

  DocumentReference<UserModel> _userProfileDocRef(String userId) {
      return _db
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc(userId)
        .withConverter<UserModel>(
            fromFirestore: (snapshots, _) => UserModel.fromFirestore(snapshots),
            toFirestore: (user, _) => user.toJson(),
        );
  }

  DocumentReference<Map<String, dynamic>> _recipeLikeRef(String recipeId, String userId) {
    return _recipesRef()
        .doc(recipeId)
        .collection('likes')
        .doc(userId);
  }

   DocumentReference<Map<String, dynamic>> _userBookmarkRef(String userId, String recipeId) {
    return _db
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(recipeId);
  }

  // --- Operasi Resep ---
  Future<void> addRecipe(RecipeModel recipe) async {
    try {
      await _recipesRef().add(recipe);
    } catch (e) {
      print('Error menambahkan resep: $e');
      throw Exception('Gagal menambahkan resep.');
    }
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    try {
      await _recipesRef().doc(recipe.id).update(recipe.toJson());
    } catch (e) {
      print('Error memperbarui resep: $e');
      throw Exception('Gagal memperbarui resep.');
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _recipesRef().doc(recipeId).delete();
    } catch (e) {
      print('Error menghapus resep: $e');
      throw Exception('Gagal menghapus resep.');
    }
  }

  Future<RecipeModel?> getRecipe(String recipeId) async {
    try {
      DocumentSnapshot<RecipeModel> doc = await _recipesRef().doc(recipeId).get();
      if (doc.exists) {
        print("Recipe fetched: ${doc.data()?.title}");
        return doc.data();
      }
      print("Recipe with ID $recipeId not found.");
      return null;
    } catch (e) {
      print('Error mengambil resep $recipeId: $e');
      return null;
    }
  }

  Stream<List<RecipeModel>> getPublicRecipes({int limit = 10}) {
    print("FirestoreService: Attempting to getPublicRecipes (appId: $appId, container: $recipeDataContainerDocId)");
    return _recipesRef()
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print("FirestoreService: getPublicRecipes snapshot received with ${snapshot.docs.length} docs.");
          // if (snapshot.docs.isNotEmpty) {
          //   print("FirestoreService: First public recipe data: ${snapshot.docs.first.data().title}");
          // }
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          print("FirestoreService: ERROR in getPublicRecipes stream: $error");
          // Kembalikan stream error agar bisa ditangani oleh StreamBuilder
          // atau kembalikan list kosong jika ingin "gagal diam-diam"
          throw error; // Melempar error agar StreamBuilder bisa menampilkannya
          // return <RecipeModel>[];
        });
  }

  Stream<List<RecipeModel>> getUserRecipes(String userId, {bool? isPublic}) {
    print("FirestoreService: Attempting to getUserRecipes for user $userId (appId: $appId, container: $recipeDataContainerDocId)");
    Query<RecipeModel> query = _recipesRef()
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (isPublic != null) {
      query = query.where('isPublic', isEqualTo: isPublic);
    }
    
    return query
        .snapshots()
        .map((snapshot) {
          print("FirestoreService: getUserRecipes snapshot received with ${snapshot.docs.length} docs for user $userId.");
          // if (snapshot.docs.isNotEmpty) {
          //   print("FirestoreService: First user recipe data: ${snapshot.docs.first.data().title}");
          // }
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          print("FirestoreService: ERROR in getUserRecipes stream for user $userId: $error");
          throw error;
          // return <RecipeModel>[];
        });
  }

  // --- Operasi Profil Pengguna ---
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _userProfileDocRef(user.uid).set(user, SetOptions(merge: true));
    } catch (e) {
      print('Error memperbarui profil pengguna: $e');
      throw Exception('Gagal memperbarui profil pengguna.');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
     try {
      DocumentSnapshot<UserModel> doc = await _userProfileDocRef(userId).get();
      return doc.data();
    } catch (e) {
      print('Error mengambil profil pengguna: $e');
      return null;
    }
  }

  // --- Operasi Komentar ---
  Future<DocumentReference<CommentModel>> addComment(CommentModel comment) async {
    try {
      DocumentReference<CommentModel> docRef = await _commentsRef(comment.recipeId).add(comment);
      await _recipesRef().doc(comment.recipeId).update({'commentsCount': FieldValue.increment(1)});
      return docRef;
    } catch (e) {
      print('Error menambahkan komentar: $e');
      throw Exception('Gagal menambahkan komentar.');
    }
  }

  Stream<List<CommentModel>> getComments(String recipeId, {int limit = 20}) {
    return _commentsRef(recipeId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          print("Error getComments: $error");
          throw error;
        });
  }

  Future<void> deleteComment(String recipeId, String commentId) async {
    try {
      await _commentsRef(recipeId).doc(commentId).delete();
      await _recipesRef().doc(recipeId).update({'commentsCount': FieldValue.increment(-1)});
    } catch (e) {
      print('Error menghapus komentar: $e');
      throw Exception('Gagal menghapus komentar.');
    }
  }

  // --- Operasi Balasan Komentar ---
   Future<void> addReply(String recipeId, String commentId, ReplyModel reply) async {
    try {
      await _repliesRef(recipeId, commentId).add(reply);
      await _commentsRef(recipeId).doc(commentId).update({'repliesCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error menambahkan balasan: $e');
      throw Exception('Gagal menambahkan balasan.');
    }
  }

  Stream<List<ReplyModel>> getReplies(String recipeId, String commentId, {int limit = 10}) {
    return _repliesRef(recipeId, commentId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          print("Error getReplies: $error");
          throw error;
        });
  }

  // --- Operasi Suka (Likes) untuk Resep ---
  Future<void> likeRecipe(String recipeId, String userId) async {
    try {
      await _recipeLikeRef(recipeId, userId).set({'likedAt': Timestamp.now()});
      await _recipesRef().doc(recipeId).update({'likesCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error menyukai resep: $e');
      throw Exception('Gagal menyukai resep.');
    }
  }

  Future<void> unlikeRecipe(String recipeId, String userId) async {
    try {
      await _recipeLikeRef(recipeId, userId).delete();
      await _recipesRef().doc(recipeId).update({'likesCount': FieldValue.increment(-1)});
    } catch (e) {
      print('Error membatalkan suka resep: $e');
      throw Exception('Gagal membatalkan suka resep.');
    }
  }

  Future<bool> isRecipeLikedByUser(String recipeId, String userId) async {
    try {
      DocumentSnapshot doc = await _recipeLikeRef(recipeId, userId).get();
      return doc.exists;
    } catch (e) {
      print('Error cek status suka resep: $e');
      return false;
    }
  }

  // --- Operasi Bookmark ---
  Future<void> bookmarkRecipe(String userId, String recipeId, {String? recipeTitle, String? recipeImageUrl}) async {
    try {
      await _userBookmarkRef(userId, recipeId).set({
        'bookmarkedAt': Timestamp.now(),
        'recipeTitle': recipeTitle,
        'recipeImageUrl': recipeImageUrl,
      });
      // *** TAMBAHKAN LOGIKA UPDATE COUNT ***
      await _recipesRef().doc(recipeId).update({'bookmarksCount': FieldValue.increment(1)});
    } catch (e) {
      print('Error bookmark resep: $e');
      throw Exception('Gagal bookmark resep.');
    }
  }

  Future<void> unbookmarkRecipe(String userId, String recipeId) async {
    try {
      await _userBookmarkRef(userId, recipeId).delete();
      // *** TAMBAHKAN LOGIKA UPDATE COUNT ***
      await _recipesRef().doc(recipeId).update({'bookmarksCount': FieldValue.increment(-1)});
    } catch (e) {
      print('Error unbookmark resep: $e');
      throw Exception('Gagal unbookmark resep.');
    }
  }

  Future<bool> isRecipeBookmarkedByUser(String userId, String recipeId) async {
    try {
      DocumentSnapshot doc = await _userBookmarkRef(userId, recipeId).get();
      return doc.exists;
    } catch (e) {
      print('Error cek status bookmark: $e');
      return false;
    }
  }

 Stream<List<Map<String, dynamic>>> getBookmarkedRecipeInfo(String userId) {
    return _db
        .collection('artifacts')
        .doc(appId)
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['recipeId'] = doc.id;
            return data;
          }).toList();
        })
        .handleError((error) {
          print("Error getBookmarkedRecipeInfo: $error");
          throw error;
        });
  }
}
