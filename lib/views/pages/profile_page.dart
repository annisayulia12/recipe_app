// lib/views/pages/profile_page.dart
import 'dart:async';
import 'dart:io'; // Untuk File

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:firebase_storage/firebase_storage.dart'; // Import firebase_storage
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/user_model.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/views/pages/change_password_page.dart';
import 'package:recipein_app/views/pages/edit_username_page.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/models/recipe_model.dart';
import 'package:recipein_app/views/widget/recipe_card.dart';

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
  StreamSubscription<UserModel?>? _userProfileSubscription;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  File? _pickedImage; // Untuk menyimpan gambar yang dipilih sementara
  bool _isUploadingPhoto = false; // Status untuk upload foto

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
    ); // Kualitas 75%
    // Anda bisa juga menambahkan opsi dari kamera:
    // final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _isUploadingPhoto = true; // Set status loading upload
      });

      final currentUser = widget.authService.getCurrentUser();
      if (currentUser == null) {
        CustomOverlayNotification.show(
          context,
          'Anda harus login untuk mengganti foto profil.',
          isSuccess: false,
        );
        setState(() {
          _isUploadingPhoto = false;
          _pickedImage = null; // Reset picked image
        });
        return;
      }

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(currentUser.uid)
            .child(
              '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ); // Nama file unik

        final uploadTask = storageRef.putFile(_pickedImage!);
        final snapshot = await uploadTask.whenComplete(() {});

        if (snapshot.state == TaskState.success) {
          final downloadUrl = await storageRef.getDownloadURL();

          // Perbarui photoUrl di Firebase Auth
          await currentUser.updatePhotoURL(downloadUrl);
          await currentUser
              .reload(); // Refresh user object untuk mendapatkan data terbaru

          // Perbarui photoUrl di Firestore melalui UserService
          final updatedUserModel = UserModel(
            uid: currentUser.uid,
            email: currentUser.email ?? '',
            displayName:
                currentUser.displayName ??
                _userProfile?.displayName ??
                'Pengguna Baru',
            photoUrl: downloadUrl, // Gunakan URL yang baru diunggah
            createdAt: _userProfile?.createdAt ?? Timestamp.now(),
          );
          await widget.userService.updateUserProfile(updatedUserModel);

          if (mounted) {
            CustomOverlayNotification.show(
              context,
              'Foto profil berhasil diperbarui.',
            );
          }
        } else {
          if (mounted) {
            CustomOverlayNotification.show(
              context,
              'Gagal mengunggah foto profil.',
              isSuccess: false,
            );
          }
        }
      } catch (e) {
        print('Error uploading profile image: $e');
        if (mounted) {
          CustomOverlayNotification.show(
            context,
            'Terjadi kesalahan saat mengunggah foto: $e',
            isSuccess: false,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploadingPhoto = false;
            _pickedImage = null; // Clear the picked image after upload attempt
          });
        }
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

            const SizedBox(height: 20),

            _buildSectionHeader('Resep Disimpan'),
            _savedRecipesSection(),
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
                    _pickedImage !=
                            null // Prioritaskan gambar yang baru dipilih
                        ? FileImage(_pickedImage!) as ImageProvider
                        : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                            ? NetworkImage(user.photoUrl!)
                            : const AssetImage(
                                  'assets/images/profile_placeholder.png',
                                )
                                as ImageProvider),
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading image: $exception');
                  // Fallback to placeholder if network image fails
                },
                child:
                    _isUploadingPhoto // Tampilkan progress indicator saat mengunggah
                        ? const CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        )
                        : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap:
                      _pickAndUploadProfileImage, // Panggil fungsi ganti foto
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryOrange,
                    child: const Icon(
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
                'Bergabung sejak: ${timeago.format(user.createdAt.toDate(), locale: 'id')}',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
    );
  }

  Widget _emptyStateMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.greyMedium),
        ),
      ),
    );
  }

  Widget _savedRecipesSection() {
    final currentUser = widget.authService.getCurrentUser();
    if (currentUser == null) {
      return _emptyStateMessage(
        'Anda harus login untuk melihat resep yang disimpan.',
      );
    }

    return StreamBuilder<List<RecipeModel>>(
      stream: widget.interactionService.getSavedRecipes(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }
        if (snapshot.hasError) {
          return _emptyStateMessage(
            'Error memuat resep disimpan: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyStateMessage('Anda belum menyimpan resep apapun.');
        }

        final savedRecipes = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: savedRecipes.length,
          itemBuilder: (context, index) {
            final recipe = savedRecipes[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: RecipeCard(
                recipe: recipe,
                recipeService: widget.recipeService,
                interactionService: widget.interactionService,
                authService: widget.authService,
                // Anda mungkin perlu menambahkan fungsi onTap untuk detail resep
                // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe))),
              ),
            );
          },
        );
      },
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
