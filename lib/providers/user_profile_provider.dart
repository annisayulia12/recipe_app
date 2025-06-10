import 'package:flutter/material.dart';
import 'package:recipein_app/models/user_model.dart';
import 'package:recipein_app/services/user_service.dart';

class UserProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); 

    try {
      _userProfile = await _userService.getUserProfile(uid);
    } catch (e) {
      _errorMessage = "Gagal memuat profil: $e";
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }
}