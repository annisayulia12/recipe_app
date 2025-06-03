import 'package:flutter/material.dart';
import 'package:recipein_app/login_page.dart';
import 'package:recipein_app/register_page.dart';
import 'package:recipein_app/services/auth_service.dart'; // Impor AuthService

class LoginRegisterTogglePage extends StatefulWidget {
  final AuthService authService; // Terima AuthService

  const LoginRegisterTogglePage({
    super.key,
    required this.authService, // Jadikan parameter wajib
  });

  @override
  State<LoginRegisterTogglePage> createState() => _LoginRegisterTogglePageState();
}

class _LoginRegisterTogglePageState extends State<LoginRegisterTogglePage> {
  bool _showLoginPage = true;

  void togglePages() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage) {
      // Teruskan authService ke LoginPage
      return LoginPage(onTapSwitch: togglePages, authService: widget.authService);
    } else {
      // Teruskan authService ke RegisterPage
      return RegisterPage(onTapSwitch: togglePages, authService: widget.authService);
    }
  }
}

