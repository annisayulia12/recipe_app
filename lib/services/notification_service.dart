import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/main.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<NotificationModel> _notificationsRef(String userId) {
    return _db.collection('artifacts').doc(appId).collection('users')
      .doc(userId).collection('notifications')
      .withConverter<NotificationModel>(
        fromFirestore: (s, _) => NotificationModel.fromFirestore(s),
        toFirestore: (n, _) => n.toJson(),
      );
  }

  Future<void> createNotification({
    required String recipientId, required User actor, required NotificationType type,
    required RecipeModel recipe, String? commentText,
  }) async {
    if (recipientId == actor.uid) return;

    final notification = NotificationModel(
      id: '', 
      recipientId: recipientId, 
      type: type,
      actorId: actor.uid, 
      actorName: actor.displayName ?? 'Seseorang', 
      actorPhotoUrl: actor.photoURL,
      recipeId: recipe.id, 
      recipeTitle: recipe.title, 
      recipeImageUrl: recipe.imageUrl,
      commentText: commentText, 
      createdAt: Timestamp.now(),
    );
    await _notificationsRef(recipientId).add(notification);
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId, {int limit = 30}) {
    return _notificationsRef(userId).orderBy('createdAt', descending: true).limit(limit)
      .snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markNotificationsAsRead(String userId, List<String> notificationIds) async {
    final batch = _db.batch();
    for (String id in notificationIds) {
      batch.update(_notificationsRef(userId).doc(id), {'isRead': true});
    }
    await batch.commit();
  }
}
