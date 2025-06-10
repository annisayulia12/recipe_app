// lib/views/pages/profile_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // <-- IMPORT PROVIDER
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/user_model.dart';
import 'package:recipein_app/providers/user_profile_provider.dart'; // <-- IMPORT PROVIDER KITA
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/services/storage_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/views/pages/change_password_page.dart';
import 'package:recipein_app/views/pages/edit_username_page.dart';
import 'package:recipein_app/views/pages/saved_recipes_page.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:timeago/timeago.dart' as timeago;

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
    // Panggil data profil dari provider saat halaman pertama kali dibuka
    // atau jika data belum ada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = widget.authService.getCurrentUser();
      final provider = Provider.of<UserProfileProvider>(context, listen: false);
      if (user != null && provider.userProfile == null) {
        provider.fetchUserProfile(user.uid);
      }
    });
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  Future<void> _pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    _pickedImage = File(image.path);

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

    final userProvider = Provider.of<UserProfileProvider>(context, listen: false);
    
    try {
      final oldImageUrl = userProvider.userProfile?.photoUrl;
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await _storageService.deleteFile(oldImageUrl);
      }
      
      final path = '${currentUser.uid}/profile.${image.path.split('.').last}';
      final downloadUrl = await _storageService.uploadFile(_pickedImage!, path);
      
      await currentUser.updatePhotoURL(downloadUrl);
      
      final updatedUserModel = userProvider.userProfile!.copyWith(photoUrl: downloadUrl);
      await widget.userService.updateUserProfile(updatedUserModel);      
      // === KUNCI PERUBAHAN ADA DI SINI ===
      // Panggil provider untuk me-refresh data di seluruh aplikasi
      await userProvider.fetchUserProfile(currentUser.uid);
      if (mounted) {
        CustomOverlayNotification.show(
          context,
          'Foto profil berhasil diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) CustomOverlayNotification.show(context, 'Terjadi kesalahan: $e', isSuccess: false);
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
      content: const Text('Apakah Anda yakin ingin keluar?', textAlign: TextAlign.center),
      confirmText: 'Keluar',
      confirmButtonColor: AppColors.error,
    );

    if (confirm == true) {
      try {
        await widget.authService.signOut();
        // --- BARU ---
        // Bersihkan data provider setelah logout
        if (mounted) {
          Provider.of<UserProfileProvider>(context, listen: false).clearUserProfile();
          CustomOverlayNotification.show(context, 'Berhasil logout.');
        }
      } catch (e) {
        if (mounted) CustomOverlayNotification.show(context, 'Gagal logout: ${e.toString()}', isSuccess: false);
      }
    }
  }

  void _navigateToEditUsernamePage() async {
    final userProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;

    if (userProfile == null) return;

    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUsernamePage(
          userService: widget.userService,
          authService: widget.authService,
          initialDisplayName: userProfile.displayName,
        ),
      ),
    );

    // === KUNCI PERUBAHAN ADA DI SINI ===
    // Jika halaman edit mengembalikan 'true' (berhasil), refresh data
    if (result == true && mounted) {
      final currentUser = widget.authService.getCurrentUser();
      if (currentUser != null) {
        await userProvider.fetchUserProfile(currentUser.uid);
      }
      CustomOverlayNotification.show(context, 'Nama pengguna berhasil diganti.');
    }
  }

  void _navigateToChangePasswordPage() {
    // Fungsi ini tidak perlu diubah
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPage(authService: widget.authService)));
  }
  
  void _navigateToSavedRecipesPage() {
    // Fungsi ini tidak perlu diubah
    Navigator.push(context, MaterialPageRoute(builder: (context) => SavedRecipesPage(
      authService: widget.authService,
      interactionService: widget.interactionService,
      recipeService: widget.recipeService,
    )));
  }

  @override
  Widget build(BuildContext context) {
    // "Dengarkan" perubahan dari UserProfileProvider
    return Consumer<UserProfileProvider>(
      builder: (context, userProvider, child) {
        // Tampilkan loading indicator jika provider sedang memuat data
        if (userProvider.isLoading && userProvider.userProfile == null) {
          return const Scaffold(
            appBar: _ProfileAppBar(),
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
          );
        }

        // Tampilkan error jika ada masalah dari provider
        if (userProvider.errorMessage != null) {
          return Scaffold(
            appBar: const _ProfileAppBar(),
            body: Center(child: Text(userProvider.errorMessage!)),
          );
        }

        // Jika tidak ada user (misal, setelah logout), tampilkan pesan
        if (userProvider.userProfile == null) {
          return const Scaffold(
            appBar: _ProfileAppBar(),
            body: Center(child: Text("Silakan login untuk melihat profil.")),
          );
        }
        
        // Data siap, bangun UI utama
        final displayedUser = userProvider.userProfile!;
        
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
                  label: 'Resep Disimpan',
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
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    // Widget ini tidak berubah, hanya saja sekarang menerima data dari `Consumer`
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
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!) as ImageProvider
                    : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? NetworkImage(user.photoUrl!)
                        : const AssetImage('assets/images/profile_placeholder.png')
                            as ImageProvider),
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading image: $exception');
                },
                child: _isUploadingPhoto
                    ? const CircularProgressIndicator(color: AppColors.primaryOrange)
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
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.white, size: 20),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 20, color: AppColors.greyMedium),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryDark),
          ),
          if (user.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Bergabung sejak: ${timeago.format(user.createdAt!.toDate(), locale: 'id')}',
                style: const TextStyle(fontSize: 12, color: AppColors.greyMedium),
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
    // Widget ini tidak berubah
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
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.greyMedium),
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
  // Widget ini tidak berubah
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Profil Saya',
        style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.white,
      elevation: 1,
      centerTitle: true,
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
