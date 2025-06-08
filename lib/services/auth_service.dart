import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService; // Dependensi ke UserService

  AuthService({required UserService userService}) : _userService = userService;

  User? getCurrentUser() => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> registerWithEmailAndPassword({
    required String email, required String password, required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
      User? firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        final userModel = UserModel(
          uid: firebaseUser.uid, email: firebaseUser.email ?? '',
          displayName: displayName, photoUrl: firebaseUser.photoURL,
          createdAt: Timestamp.now(),
        );
        // Gunakan UserService untuk membuat profil
        await _userService.createUserProfile(userModel);
      }
      return userCredential;
    } catch (e) {
      print("Error during registration: $e");
      rethrow;
    }
  }
  
  Future<UserCredential> signInWithEmailAndPassword({
    required String email, required String password,
  }) async => await _auth.signInWithEmailAndPassword(email: email, password: password);
  
  Future<void> signOut() async => await _auth.signOut();
}