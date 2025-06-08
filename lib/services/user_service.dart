import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/main.dart'; // Untuk appId

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<UserModel> _userProfileDocRef(String userId) {
    return _db.collection('artifacts').doc(appId).collection('users')
      .doc(userId).collection('profile').doc(userId)
      .withConverter<UserModel>(
        fromFirestore: (snapshots, _) => UserModel.fromFirestore(snapshots),
        toFirestore: (user, _) => user.toJson(),
      );
  }

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _userProfileDocRef(user.uid).set(user);
    } catch (e) {
      print("Error creating user profile: $e");
      throw Exception("Gagal membuat profil pengguna.");
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _userProfileDocRef(user.uid).set(user, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user profile: $e");
      throw Exception("Gagal memperbarui profil pengguna.");
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _userProfileDocRef(userId).get();
      return snapshot.data();
    } catch (e) {
      print("Error getting user profile: $e");
      return null;
    }
  }
}
