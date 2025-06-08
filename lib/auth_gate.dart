// lib/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk User?
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/notification_service.dart';
import 'package:recipein_app/login_register_toggle_page.dart'; // Halaman login/register Anda
import 'package:recipein_app/views/widget/button_nav_bar.dart';  // Impor ButtonNavBar Anda

class AuthGate extends StatelessWidget {
  final AuthService authService;
  final UserService userService;
  final RecipeService recipeService;
  final InteractionService interactionService;
  final NotificationService notificationService;

  const AuthGate({
    super.key,
    required this.authService,
    required this.userService,
    required this.recipeService,
    required this.interactionService,
    required this.notificationService,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ButtonNavBar(
            authService: authService, 
            userService: userService, 
            recipeService: recipeService,
            interactionService: interactionService, 
            notificationService: notificationService,
          );
        }
        return LoginRegisterTogglePage(
          authService: authService,
        );
      },
    );
  }
}
