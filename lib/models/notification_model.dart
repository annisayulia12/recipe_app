import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/models/enums/notification_type.dart';

class NotificationModel {
  final String id;
  final NotificationType type;
  final String recipientId; // UID pengguna yang menerima notifikasi
  final String actorId; // UID pengguna yang melakukan aksi
  final String actorName; // Nama pengguna yang melakukan aksi
  final String? actorPhotoUrl; // Foto profil pengguna yang melakukan aksi
  final String recipeId; // ID resep yang terkait
  final String? recipeImageUrl; // Gambar resep untuk thumbnail
  final String recipeTitle; // Judul resep untuk ditampilkan
  final String? commentText; // Teks komentar/balasan (jika ada)
  final Timestamp createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.recipeId,
    this.recipeImageUrl,
    required this.recipeTitle,
    this.commentText,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name, // Simpan enum sebagai string
      'recipientId': recipientId,
      'actorId': actorId,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'recipeId': recipeId,
      'recipeImageUrl': recipeImageUrl,
      'recipeTitle': recipeTitle,
      'commentText': commentText,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: NotificationType.values.byName(data['type'] ?? 'like'), // Konversi string kembali ke enum
      recipientId: data['recipientId'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorPhotoUrl: data['actorPhotoUrl'],
      recipeId: data['recipeId'] ?? '',
      recipeImageUrl: data['recipeImageUrl'],
      recipeTitle: data['recipeTitle'] ?? '',
      commentText: data['commentText'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}