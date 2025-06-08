import 'package:cloud_firestore/cloud_firestore.dart';

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