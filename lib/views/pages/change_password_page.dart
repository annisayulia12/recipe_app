// lib/views/pages/change_password_page.dart
import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart'; //
import 'package:recipein_app/services/auth_service.dart'; //
import 'package:firebase_auth/firebase_auth.dart'; // Ini sudah harus ada
import 'package:recipein_app/widgets/custom_overlay_notification.dart'; //
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart'; //

class ChangePasswordPage extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordPage({super.key, required this.authService});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;
  bool _isLoading = false;
  bool _isFormDirty = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_setFormDirty);
    _newPasswordController.addListener(_setFormDirty);
    _confirmNewPasswordController.addListener(_setFormDirty);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_setFormDirty);
    _newPasswordController.removeListener(_setFormDirty);
    _confirmNewPasswordController.removeListener(_setFormDirty);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _setFormDirty() {
    if (!_isFormDirty &&
        (_currentPasswordController.text.isNotEmpty ||
            _newPasswordController.text.isNotEmpty ||
            _confirmNewPasswordController.text.isNotEmpty)) {
      setState(() {
        _isFormDirty = true;
      });
    } else if (_isFormDirty &&
        _currentPasswordController.text.isEmpty &&
        _newPasswordController.text.isEmpty &&
        _confirmNewPasswordController.text.isEmpty) {
      setState(() {
        _isFormDirty = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmNewPasswordController.text.isEmpty) {
      CustomOverlayNotification.show(
        context,
        'Kata sandi baru dan konfirmasi tidak boleh kosong.',
        isSuccess: false,
      );
      return;
    }
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      CustomOverlayNotification.show(
        context,
        'Kata sandi baru dan konfirmasi tidak cocok.',
        isSuccess: false,
      );
      return;
    }
    if (_newPasswordController.text.length < 6) {
      CustomOverlayNotification.show(
        context,
        'Kata sandi baru minimal 6 karakter.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = widget.authService.getCurrentUser();

    if (user == null) {
      if (mounted) {
        CustomOverlayNotification.show(
          context,
          'Pengguna tidak login. Silakan login ulang.',
          isSuccess: false,
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      print("Error changing password: ${e.code} - ${e.message}");
      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = 'Kata sandi lama salah.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'Untuk alasan keamanan, silakan login ulang dan coba lagi.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah.';
      } else {
        errorMessage = 'Gagal memperbarui kata sandi: ${e.message}';
      }
      if (mounted) {
        CustomOverlayNotification.show(context, errorMessage, isSuccess: false);
      }
    } catch (e) {
      print("Error changing password: $e");
      if (mounted) {
        CustomOverlayNotification.show(
          context,
          'Terjadi kesalahan tidak diketahui: ${e.toString()}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isFormDirty) {
      return true;
    }
    final shouldPop = await showCustomConfirmationDialog(
      context: context,
      title: 'Batal Mengubah Kata Sandi?',
      content: const Text(
        'Perubahan yang Anda lakukan mungkin belum disimpan.',
        textAlign: TextAlign.center,
      ),
      confirmText: 'Batal',
      cancelText: 'Lanjutkan Edit',
      confirmButtonColor: AppColors.error,
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_circle_left_outlined,
              color: AppColors.primaryOrange,
              size: 30,
            ), //
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop(false);
              }
            },
          ),
          title: const Text(
            'Ganti Kata Sandi',
            style: TextStyle(
              color: AppColors.secondaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ), //
          backgroundColor: AppColors.white, //
          elevation: 1,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kata Sandi Lama',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ), //
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  hintText: 'Masukkan kata sandi lama anda',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.greyMedium,
                    ), //
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Kata Sandi Baru',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ), //
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  hintText: 'Buat kata sandi baru anda',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.greyMedium,
                    ), //
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Konfirmasi Kata Sandi Baru',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ), //
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmNewPasswordController,
                obscureText: _obscureConfirmNewPassword,
                decoration: InputDecoration(
                  hintText: 'Konfirmasi kata sandi baru anda',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.greyMedium,
                    ), //
                    onPressed: () {
                      setState(() {
                        _obscureConfirmNewPassword =
                            !_obscureConfirmNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  ) //
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormDirty ? _changePassword : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal, //
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: AppColors.white),
                      ), //
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
