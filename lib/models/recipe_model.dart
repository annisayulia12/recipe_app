import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int bookmarksCount;

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
    this.bookmarksCount = 0,
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
      'bookmarksCount': bookmarksCount,
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
      bookmarksCount: data['bookmarksCount'] ?? 0,
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
    int? bookmarksCount,
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
      bookmarksCount: bookmarksCount ?? this.bookmarksCount, 
    );
  }
}