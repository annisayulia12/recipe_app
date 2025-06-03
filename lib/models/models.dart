// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ... (UserModel, CommentModel, ReplyModel tetap sama) ...

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(), // Penanganan lebih baik
    );
  }
   factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : Timestamp.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    Timestamp? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


class RecipeModel {
  final String id;
  final String title;
  final String? description;
  final List<String> ingredients;
  final List<String> steps;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final Timestamp createdAt; // Jadikan non-nullable, berikan default jika perlu
  final Timestamp? updatedAt;
  final bool isPublic;
  final int likesCount;
  final int commentsCount;

  RecipeModel({
    required this.id,
    required this.title,
    this.description,
    required this.ingredients,
    required this.steps,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.createdAt,
    this.updatedAt,
    required this.isPublic,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublic': isPublic,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    };
  }

  factory RecipeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // DEBUG: Print data mentah yang diterima dari Firestore
    // print("RecipeModel.fromFirestore - Raw data for doc ${doc.id}: $data");

    return RecipeModel(
      id: doc.id,
      title: data['title'] ?? 'Tanpa Judul',
      description: data['description'],
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
      imageUrl: data['imageUrl'],
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Anonim', // Default jika ownerName null
      ownerPhotoUrl: data['ownerPhotoUrl'],
      // Penanganan lebih aman untuk Timestamp
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : null,
      isPublic: data['isPublic'] ?? true, // Default ke publik jika tidak ada
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    String? imageUrl,
    String? ownerId,
    String? ownerName,
    String? ownerPhotoUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isPublic,
    int? likesCount,
    int? commentsCount,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}

class CommentModel {
  final String id;
  final String recipeId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final int likesCount;
  final int repliesCount;

  CommentModel({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.repliesCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
    };
  }

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : null,
      likesCount: data['likesCount'] ?? 0,
      repliesCount: data['repliesCount'] ?? 0,
    );
  }
   CommentModel copyWith({
    String? id,
    String? recipeId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? text,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? likesCount,
    int? repliesCount,
  }) {
    return CommentModel(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
    );
  }
}

class ReplyModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final int likesCount;

  ReplyModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
    };
  }

  factory ReplyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReplyModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : null,
      likesCount: data['likesCount'] ?? 0,
    );
  }
   ReplyModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? text,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? likesCount,
  }) {
    return ReplyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}
