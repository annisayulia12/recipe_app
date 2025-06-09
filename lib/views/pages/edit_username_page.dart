// lib/views/pages/edit_username_page.dart
import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/models/user_model.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <<< TAMBAHKAN INI

class EditUsernamePage extends StatefulWidget {
  final UserService userService;
  final AuthService authService;
  final String initialDisplayName;

  const EditUsernamePage({
    super.key,
    required this.userService,
    required this.authService,
    required this.initialDisplayName,
  });

  @override
  State<EditUsernamePage> createState() => _EditUsernamePageState();
}

class _EditUsernamePageState extends State<EditUsernamePage> {
  late TextEditingController _usernameController;
  bool _isLoading = false;
  bool _isFormDirty = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.initialDisplayName,
    );
    _usernameController.addListener(_setFormDirty);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_setFormDirty);
    _usernameController.dispose();
    super.dispose();
  }

  void _setFormDirty() {
    if (_usernameController.text != widget.initialDisplayName &&
        !_isFormDirty) {
      setState(() {
        _isFormDirty = true;
      });
    } else if (_usernameController.text == widget.initialDisplayName &&
        _isFormDirty) {
      setState(() {
        _isFormDirty = false;
      });
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      CustomOverlayNotification.show(
        context,
        'Nama pengguna tidak boleh kosong.',
        isSuccess: false,
      );
      return;
    }
    if (_usernameController.text.trim() == widget.initialDisplayName) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isLoading = true);
    final currentUser = widget.authService.getCurrentUser();

    if (currentUser == null) {
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
      await currentUser.updateDisplayName(_usernameController.text.trim());
      await currentUser.reload();
      final updatedFirebaseUser = widget.authService.getCurrentUser();

      final updatedUserModel = UserModel(
        uid: updatedFirebaseUser!.uid,
        email: updatedFirebaseUser.email ?? '',
        displayName:
            updatedFirebaseUser.displayName ?? _usernameController.text.trim(),
        photoUrl: updatedFirebaseUser.photoURL,
        createdAt: Timestamp.now(), // <<< UBAH DI SINI
      );
      await widget.userService.updateUserProfile(updatedUserModel);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print("Error updating username: $e");
      if (mounted) {
        CustomOverlayNotification.show(
          context,
          'Gagal memperbarui nama pengguna: ${e.toString()}',
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
      title: 'Batal Mengubah Nama Pengguna?',
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
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop(false);
              }
            },
          ),
          title: const Text(
            'Ganti Nama Pengguna',
            style: TextStyle(
              color: AppColors.secondaryTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.white,
          elevation: 1,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama Pengguna Baru',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama pengguna baru',
                  suffixIcon:
                      _isFormDirty
                          ? const Icon(
                            Icons.edit,
                            color: AppColors.primaryOrange,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  )
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormDirty ? _updateUsername : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
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
                        'Simpan Perubahan',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
