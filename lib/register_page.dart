import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/custom_button.dart';
import 'package:recipein_app/custom_textfield.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onTapSwitch;
  final AuthService authService; // Terima AuthService

  const RegisterPage({
    super.key,
    required this.onTapSwitch,
    required this.authService, // Jadikan parameter wajib
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // HAPUS: final AuthService _authService = AuthService(); // Gunakan instance dari widget
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _register() async {
    if (!mounted) return;
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog("Semua field harus diisi.");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog("Kata sandi dan konfirmasi kata sandi tidak cocok.");
      return;
    }
    if (_passwordController.text.length < 6) {
      _showErrorDialog("Kata sandi minimal 6 karakter.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Gunakan widget.authService
      await widget.authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _usernameController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = "Terjadi kesalahan saat registrasi.";
      if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar. Silakan login.';
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
      builder: (ctx) => AlertDialog(
        title: const Text('Registrasi Gagal'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: screenHeight * 0.22,
                margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: Image.network(
                  'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600',
                  fit: BoxFit.contain,
                   errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Text(
                'Gabung dengan kami!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
              ),
              SizedBox(height: screenHeight * 0.03),
              CustomTextField(
                controller: _emailController,
                hintText: 'Masukkan email anda',
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                controller: _usernameController,
                hintText: 'Buat nama pengguna anda',
                labelText: 'Nama Pengguna',
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Buat kata sandi anda',
                labelText: 'Kata Sandi',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Konfirmasi kata sandi anda',
                labelText: 'Konfirmasi Kata Sandi',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
               _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Daftar',
                      onPressed: _register,
                    ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Sudah memiliki akun? ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: widget.onTapSwitch,
                    child: const Text(
                      'Masuk disini!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A7C76)),
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