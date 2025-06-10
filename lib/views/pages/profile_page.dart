import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/user_model.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/services/storage_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/views/pages/change_password_page.dart';
import 'package:recipein_app/views/pages/edit_username_page.dart';
import 'package:recipein_app/views/pages/saved_recipes_page.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;
  final UserService userService;
  final InteractionService interactionService;
  final RecipeService recipeService;

  const ProfilePage({
    super.key,
    required this.authService,
    required this.userService,
    required this.interactionService,
    required this.recipeService,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final StorageService _storageService = StorageService();

  StreamSubscription<UserModel?>? _userProfileSubscription;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  File? _pickedImage;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _listenToUserProfile();
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  @override
  void dispose() {
    _userProfileSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserProfile() {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    final currentUser = widget.authService.getCurrentUser();
    if (currentUser != null) {
      widget.userService
          .getUserProfile(currentUser.uid)
          .then((userModel) {
            if (mounted) {
              setState(() {
                _userProfile = userModel;
                _isLoadingProfile = false;
              });
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _errorMessage = "Gagal memuat profil: $e";
                _isLoadingProfile = false;
              });
              CustomOverlayNotification.show(
                context,
                'Gagal memuat profil: $e',
                isSuccess: false,
              );
            }
          });
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = "Pengguna tidak login.";
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      _pickedImage = File(image.path);
      _isUploadingPhoto = true;
    });

    final currentUser = widget.authService.getCurrentUser();
    if (currentUser == null) {
      CustomOverlayNotification.show(
        context,
        'Anda harus login.',
        isSuccess: false,
      );
      setState(() => _isUploadingPhoto = false);
      return;
    }

    try {
      final oldImageUrl = _userProfile?.photoUrl;
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await _storageService.deleteFile(oldImageUrl);
      }

      final fileExtension = image.path.split('.').last;
      final path = '${currentUser.uid}/profile.$fileExtension';

      final downloadUrl = await _storageService.uploadFile(_pickedImage!, path);

      await currentUser.updatePhotoURL(downloadUrl);
      await currentUser.reload();

      final updatedUserModel = _userProfile!.copyWith(photoUrl: downloadUrl);
      await widget.userService.updateUserProfile(updatedUserModel);

      setState(() {
        _userProfile = updatedUserModel;
      });

      if (mounted) {
        CustomOverlayNotification.show(
          context,
          'Foto profil berhasil diperbarui.',
        );
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      if (mounted) {
        CustomOverlayNotification.show(
          context,
          'Terjadi kesalahan: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _pickedImage = null;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final bool? confirm = await showCustomConfirmationDialog(
      context: context,
      title: 'Konfirmasi Logout',
      content: const Text(
        'Apakah Anda yakin ingin keluar?',
        textAlign: TextAlign.center,
      ),
      confirmText: 'Keluar',
      confirmButtonColor: AppColors.error,
    );

    if (confirm == true) {
      try {
        await widget.authService.signOut();
        if (mounted) {
          CustomOverlayNotification.show(context, 'Berhasil logout.');
        }
      } catch (e) {
        if (mounted) {
          CustomOverlayNotification.show(
            context,
            'Gagal logout: ${e.toString()}',
            isSuccess: false,
          );
        }
      }
    }
  }

  void _navigateToEditUsernamePage() async {
    if (_userProfile == null) {
      CustomOverlayNotification.show(
        context,
        'Profil belum dimuat. Coba lagi.',
        isSuccess: false,
      );
      return;
    }
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditUsernamePage(
              userService: widget.userService,
              authService: widget.authService,
              initialDisplayName: _userProfile!.displayName,
            ),
      ),
    );
    if (result == true) {
      CustomOverlayNotification.show(
        context,
        'Nama pengguna berhasil diganti.',
      );
    }
  }

  void _navigateToChangePasswordPage() async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangePasswordPage(authService: widget.authService),
      ),
    );
    if (result == true) {
      CustomOverlayNotification.show(context, 'Kata sandi berhasil diganti.');
    }
  }

  void _navigateToSavedRecipesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SavedRecipesPage(
              authService: widget.authService,
              interactionService: widget.interactionService,
              recipeService: widget.recipeService,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = widget.authService.getCurrentUser();
    final displayedUser =
        _userProfile ??
        UserModel(
          uid: firebaseUser?.uid ?? 'unknown',
          email: firebaseUser?.email ?? 'email@example.com',
          displayName: firebaseUser?.displayName ?? 'Pengguna Baru',
          photoUrl: firebaseUser?.photoURL,
          createdAt: Timestamp.now(),
        );

    if (_isLoadingProfile) {
      return const Scaffold(
        appBar: _ProfileAppBar(),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: const _ProfileAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 50,
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _listenToUserProfile,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: const _ProfileAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(displayedUser),
            const SizedBox(height: 10),

            _buildProfileOption(
              icon: Icons.bookmark_border,
              label: 'Resep Tersimpan',
              onTap: _navigateToSavedRecipesPage,
            ),
            const SizedBox(height: 8),

            _buildProfileOption(
              icon: Icons.lock_outline,
              label: 'Ganti Kata Sandi',
              onTap: _navigateToChangePasswordPage,
            ),
            const SizedBox(height: 8),
            _buildProfileOption(
              icon: Icons.logout,
              label: 'Keluar',
              onTap: _handleSignOut,
              iconColor: AppColors.error,
              textColor: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.white,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.greyLight,
                backgroundImage:
                    _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                            ? NetworkImage(user.photoUrl!)
                            : const AssetImage(
                                  'assets/images/profile_placeholder.png',
                                )
                                as ImageProvider),
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading image: $exception');
                },
                child:
                    _isUploadingPhoto
                        ? const CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        )
                        : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadProfileImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryOrange,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _navigateToEditUsernamePage,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 20, color: AppColors.greyMedium),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
            ),
          ),
          if (user.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Bergabung sejak: ${timeago.format(user.createdAt!.toDate(), locale: 'id')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = AppColors.primaryOrange,
    Color textColor = AppColors.textPrimaryDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.greyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Profil Saya',
        style: TextStyle(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.white,
      elevation: 1,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
