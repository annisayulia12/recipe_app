import 'package:cloud_firestore/cloud_firestore.dart';

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