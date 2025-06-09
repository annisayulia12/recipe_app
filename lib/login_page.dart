// lib/login_page.dart
// *** PERLU PENYESUAIAN ***
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/custom_button.dart';
import 'package:recipein_app/custom_textfield.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onTapSwitch;
  final AuthService authService; // Terima AuthService

  const LoginPage({
    super.key,
    required this.onTapSwitch,
    required this.authService, // Jadikan parameter wajib
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _login() async {
    if (!mounted) return;
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Email dan kata sandi tidak boleh kosong.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Gunakan widget.authService
      await widget.authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = "Terjadi kesalahan saat login.";
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = "Email atau kata sandi salah.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Format email tidak valid.";
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Terjadi kesalahan tidak diketahui: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Login Gagal'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: screenHeight * 0.25,
                margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                child: Image.asset(
                  'assets/images/logo_recipein.png', // Ganti dengan path gambar yang sesuai
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
              Text(
                'Hai, selamat datang!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              CustomTextField(
                controller: _emailController,
                hintText: 'Masukkan email anda',
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Masukkan kata sandi anda',
                labelText: 'Kata Sandi',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fitur lupa kata sandi belum diimplementasikan.',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(color: Color(0xFF2A7C76)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(text: 'Masuk', onPressed: _login),
              SizedBox(height: screenHeight * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Belum memiliki akun? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: widget.onTapSwitch,
                    child: const Text(
                      'Daftar disini!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A7C76),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
