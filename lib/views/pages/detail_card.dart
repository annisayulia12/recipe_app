import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/views/pages/edit_recipe_page.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:share_plus/share_plus.dart';

// Impor barrel file untuk komponen-komponen UI
import 'detail/widgets/widgets.dart';

// Helper class untuk membawa semua data yang dibutuhkan dari future
class RecipeDetailBundle {
  final RecipeModel recipe;
  final bool isLiked;
  final bool isBookmarked;

  RecipeDetailBundle({
    required this.recipe,
    required this.isLiked,
    required this.isBookmarked,
  });
}

class DetailCard extends StatefulWidget {
  final String recipeId;
  final RecipeService recipeService;
  final InteractionService interactionService;
  final AuthService authService;

  const DetailCard({
    super.key, 
    required this.recipeId, 
    required this.recipeService, 
    required this.interactionService, 
    required this.authService
  });

  @override
  State<DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends State<DetailCard> {
  late Future<RecipeDetailBundle?> _detailsFuture;
  
  // State lokal untuk interaksi UI setelah data awal dimuat
  RecipeModel? _recipe;
  User? _currentUser;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isInteractionLoading = false;

  final String _dynamicLinkDomain = "recipeinapp.page.link";

  @override
  void initState() {
    super.initState();
    _currentUser = widget.authService.getCurrentUser();
    _detailsFuture = _loadRecipeDetails();
  }

  // --- SEMUA METODE HELPER YANG DIPERLUKAN ---

  Future<RecipeDetailBundle?> _loadRecipeDetails() async {
    try {
      final recipeData = await widget.recipeService.getRecipe(widget.recipeId);
      if (recipeData == null) return null;

      bool liked = false;
      bool bookmarked = false;
      if (_currentUser != null) {
        final results = await Future.wait([
          widget.interactionService.isRecipeLikedByUser(recipeData.id, _currentUser!.uid),
          widget.interactionService.isRecipeBookmarkedByUser(_currentUser!.uid, recipeData.id),
        ]);
        liked = results[0];
        bookmarked = results[1];
      }
      
      // Update state lokal setelah data diambil, ini penting untuk pembaruan UI instan
      if (mounted) {
        setState(() {
          _recipe = recipeData;
          _isLiked = liked;
          _isBookmarked = bookmarked;
        });
      }
      return RecipeDetailBundle(recipe: recipeData, isLiked: liked, isBookmarked: bookmarked);
    } catch (e) {
      print("Error loading recipe details: $e");
      rethrow;
    }
  }
  
  Future<void> _toggleLike() async {
    if (_isInteractionLoading || _currentUser == null || _recipe == null) return;
    setState(() => _isInteractionLoading = true);
    final currentlyLiked = _isLiked;
    
    // Optimistic UI update dengan pengecekan
    setState(() {
      _isLiked = !currentlyLiked;
      int newLikesCount = _isLiked ? _recipe!.likesCount + 1 : (_recipe!.likesCount > 0 ? _recipe!.likesCount - 1 : 0);
      _recipe = _recipe!.copyWith(likesCount: newLikesCount);
    });
    try {
      if (currentlyLiked) {
        await widget.interactionService.unlikeRecipe(_recipe!.id, _currentUser!.uid);
      } else {
        await widget.interactionService.likeRecipe(_recipe!, _currentUser!);
      }
    } catch (e) {
      // Rollback jika gagal
      setState(() {
        _isLiked = currentlyLiked;
        int newLikesCount = currentlyLiked ? _recipe!.likesCount - 1 : _recipe!.likesCount + 1;
        _recipe = _recipe!.copyWith(likesCount: newLikesCount);
      });
      if(mounted) CustomOverlayNotification.show(context, 'Gagal memproses suka', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isInteractionLoading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isInteractionLoading || _currentUser == null || _recipe == null) return;
    setState(() => _isInteractionLoading = true);
    final currentlyBookmarked = _isBookmarked;

    // Optimistic UI update dengan pengecekan
    setState(() {
      _isBookmarked = !currentlyBookmarked;
      int newBookmarksCount = _isBookmarked ? _recipe!.bookmarksCount + 1 : (_recipe!.bookmarksCount > 0 ? _recipe!.bookmarksCount - 1 : 0);
      _recipe = _recipe!.copyWith(bookmarksCount: newBookmarksCount);
    });

    try {
      if (currentlyBookmarked) {
        await widget.interactionService.unbookmarkRecipe(_currentUser!.uid, _recipe!.id);
      } else {
        await widget.interactionService.bookmarkRecipe(_recipe!, _currentUser!);
      }
      if (mounted) CustomOverlayNotification.show(context, _isBookmarked ? 'Postingan berhasil disimpan' : 'Simpanan resep dihapus');
    } catch (e) {
      // Rollback jika gagal
      setState(() {
        _isBookmarked = currentlyBookmarked;
        int newBookmarksCount = currentlyBookmarked ? _recipe!.bookmarksCount - 1 : _recipe!.bookmarksCount + 1;
        _recipe = _recipe!.copyWith(bookmarksCount: newBookmarksCount);
      });
      if(mounted) CustomOverlayNotification.show(context, 'Gagal memproses simpanan', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isInteractionLoading = false);
    }
  }

  Future<String> _generateDeepLink() async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse("https://recipein-app.com/resep?id=${_recipe!.id}"),
      uriPrefix: "https://$_dynamicLinkDomain",
      androidParameters: const AndroidParameters(packageName: "com.example.recipein_app", minimumVersion: 0),
      iosParameters: const IOSParameters(bundleId: "com.example.recipeinApp", minimumVersion: "0"),
    );
    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    return shortLink.shortUrl.toString();
  }

  void _shareRecipe() async {
    if (_recipe == null) return;
    final String recipeUrl = await _generateDeepLink();
    final String shareText = "Lihat resep lezat '${_recipe!.title}' yang saya temukan di aplikasi RecipeIn! \n\n$recipeUrl";
    Share.share(shareText, subject: "Resep Lezat: ${_recipe!.title}");
  }

  void _copyLink() async {
    if (_recipe == null) return;
    final String recipeUrl = await _generateDeepLink();
    await Clipboard.setData(ClipboardData(text: recipeUrl));
    if (mounted) CustomOverlayNotification.show(context, 'Tautan berhasil disalin');
  }

  Future<void> _showDeleteConfirmationDialog() async {
    if (_recipe == null) return;

    final bool? confirm = await showCustomConfirmationDialog(
      context: context,
      title: 'Hapus Resep?',
      content: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: <TextSpan>[
            const TextSpan(text: 'Apakah anda yakin ingin menghapus resep '),
            TextSpan(text: '"${_recipe!.title}"?\n\n', style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: 'Tindakan ini tidak dapat dibatalkan.'),
          ],
        ),
      ),
      confirmText: 'Hapus',
      confirmButtonColor: AppColors.error,
    );
    
    if (confirm == true) {
      _deleteRecipe();
    }
  }

  Future<void> _deleteRecipe() async {
    if (_recipe == null || !mounted) return;
    
    try {
      await widget.recipeService.deleteRecipe(_recipe!.id);
      if (mounted) {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 200), () {
          CustomOverlayNotification.show(context, 'Resep berhasil dihapus');
        });
      }
    } catch (e) {
      if (mounted) CustomOverlayNotification.show(context, 'Gagal menghapus resep: ${e.toString()}', isSuccess: false);
    }
  }

  void _navigateToEditPage() {
    if (_recipe == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipePage(
          initialRecipe: _recipe!,
          recipeService: widget.recipeService,
          authService: widget.authService,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          _detailsFuture = _loadRecipeDetails();
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecipeDetailBundle?>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center))));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: const Center(child: Text('Resep tidak ditemukan.')));
        }

        // Data sekarang di-assign ke state hanya sekali di initState/_loadRecipeDetails
        // Di sini kita bisa dengan aman menggunakan _recipe yang sudah ada di state.
        if (_recipe == null) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: const Center(child: Text('Resep tidak valid.')));
        }
        final recipeData = _recipe!;
        final bool isOwner = _currentUser?.uid == recipeData.ownerId;

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30), onPressed: () => Navigator.of(context).pop()),
            backgroundColor: AppColors.white,
            elevation: 1,
            title: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: recipeData.ownerPhotoUrl != null && recipeData.ownerPhotoUrl!.isNotEmpty
                    ? NetworkImage(recipeData.ownerPhotoUrl!)
                    : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(recipeData.ownerName, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ]),
            titleSpacing: 0,
            actions: [
              if (isOwner) PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _navigateToEditPage();
                  else if (value == 'delete') _showDeleteConfirmationDialog();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: AppColors.textPrimaryDark), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.error))])),
                ],
              ),
            ],
          ),
          bottomNavigationBar: InteractionBottomBar(
            recipe: recipeData,
            isLiked: _isLiked,
            isBookmarked: _isBookmarked,
            onLikeTap: _toggleLike,
            onBookmarkTap: _toggleBookmark,
            onCopyTap: _copyLink,
            onShareTap: _shareRecipe,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- UI sekarang bersih dan memanggil komponen ---
                RecipeHeader(recipe: recipeData),
                RecipeInfoSection(recipe: recipeData),
                CommentSection(
                  recipeId: recipeData.id,
                  recipe: recipeData,
                  interactionService: widget.interactionService,
                  currentUser: _currentUser,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
