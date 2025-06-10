// lib/providers/user_profile_provider.dart

import 'package:flutter/material.dart';
import 'package:recipein_app/models/user_model.dart';
import 'package:recipein_app/services/user_service.dart';

class UserProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters agar UI bisa mengakses data dengan aman
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fungsi untuk memuat atau me-refresh data profil
  Future<void> fetchUserProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    // Notify listeners di awal untuk menunjukkan state loading
    notifyListeners(); 

    try {
      _userProfile = await _userService.getUserProfile(uid);
    } catch (e) {
      _errorMessage = "Gagal memuat profil: $e";
      _userProfile = null;
    } finally {
      _isLoading = false;
      // Notify listeners lagi setelah selesai, dengan data baru atau pesan error
      notifyListeners(); 
    }
  }

  // Fungsi untuk membersihkan profil saat logout
  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }
}