import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/views/pages/edit_recipe_page.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:share_plus/share_plus.dart';

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
  final FirestoreService firestoreService;
  final AuthService authService;

  const DetailCard({
    super.key,
    required this.recipeId,
    required this.firestoreService,
    required this.authService,
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
      final recipeData = await widget.firestoreService.getRecipe(widget.recipeId);
      if (recipeData == null) return null;

      bool liked = false;
      bool bookmarked = false;
      if (_currentUser != null) {
        final results = await Future.wait([
          widget.firestoreService.isRecipeLikedByUser(recipeData.id, _currentUser!.uid),
          widget.firestoreService.isRecipeBookmarkedByUser(_currentUser!.uid, recipeData.id),
        ]);
        liked = results[0];
        bookmarked = results[1];
      }
      
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
        await widget.firestoreService.unlikeRecipe(_recipe!.id, _currentUser!.uid);
      } else {
        await widget.firestoreService.likeRecipe(_recipe!.id, _currentUser!.uid);
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
        await widget.firestoreService.unbookmarkRecipe(_currentUser!.uid, _recipe!.id);
      } else {
        await widget.firestoreService.bookmarkRecipe(_currentUser!.uid, _recipe!.id, recipeTitle: _recipe!.title, recipeImageUrl: _recipe!.imageUrl);
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: SingleChildScrollView(child: ListBody(children: <Widget>[Text('Apakah Anda yakin ingin menghapus resep "${_recipe!.title}"?'), const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(fontWeight: FontWeight.bold))])),
          actions: <Widget>[
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Hapus'),
              onPressed: () { Navigator.of(context).pop(); _deleteRecipe(); },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecipe() async {
    if (_recipe == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menghapus resep...')));
    try {
      await widget.firestoreService.deleteRecipe(_recipe!.id);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Resep berhasil dihapus.'), backgroundColor: AppColors.success));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus resep: ${e.toString()}'), backgroundColor: AppColors.error));
    }
  }

  void _navigateToEditPage() {
    if (_recipe == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipePage(
          initialRecipe: _recipe!,
          firestoreService: widget.firestoreService,
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
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppColors.primaryOrange)), body: const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppColors.primaryOrange)), body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center))));
        }
        if (!snapshot.hasData || snapshot.data == null || _recipe == null) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppColors.primaryOrange)), body: const Center(child: Text('Resep tidak ditemukan.')));
        }

        final recipeData = _recipe!;
        final bool isOwner = _currentUser?.uid == recipeData.ownerId;

        const TextStyle headingStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark);
        const TextStyle bodyTextStyle = TextStyle(fontSize: 14, color: AppColors.textSecondaryDark, height: 1.5);
        const TextStyle metaTextStyle = TextStyle(fontSize: 12, color: AppColors.greyMedium);

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
          bottomNavigationBar: _buildInteractionBottomBar(recipeData),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipeData.imageUrl != null && recipeData.imageUrl!.isNotEmpty)
                  Image.network(recipeData.imageUrl!, width: double.infinity, height: 250, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) => (loadingProgress == null) ? child : Container(height: 250, color: AppColors.greyLight, child: const Center(child: CircularProgressIndicator())), errorBuilder: (context, error, stackTrace) => Container(height: 250, color: AppColors.greyLight, child: const Icon(Icons.broken_image, color: AppColors.greyMedium)))
                else
                  Container(width: double.infinity, height: 250, color: AppColors.greyLight, child: const Icon(Icons.restaurant_menu, size: 60, color: AppColors.greyMedium)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipeData.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
                      const SizedBox(height: 4),
                      Text("Diposting pada ${recipeData.createdAt.toDate().toString().substring(0, 10)}", style: metaTextStyle),
                      if (recipeData.updatedAt != null) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("Diperbarui pada ${recipeData.updatedAt!.toDate().toString().substring(0, 10)}", style: metaTextStyle.copyWith(fontStyle: FontStyle.italic))),
                      if (recipeData.description != null && recipeData.description!.isNotEmpty) ...[const SizedBox(height: 16), Text(recipeData.description!, style: bodyTextStyle)],
                      const Divider(height: 32),
                      const Text('Bahan-bahan', style: headingStyle), const SizedBox(height: 8),
                      if (recipeData.ingredients.isEmpty) const Text("Tidak ada bahan yang dicantumkan.", style: bodyTextStyle) else ...recipeData.ingredients.map((val) => Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text('• $val', style: bodyTextStyle))),
                      const SizedBox(height: 24),
                      const Text('Langkah-langkah', style: headingStyle), const SizedBox(height: 8),
                      if (recipeData.steps.isEmpty) const Text("Tidak ada langkah-langkah yang dicantumkan.", style: bodyTextStyle) else ...recipeData.steps.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${entry.key + 1}. ', style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold)), Expanded(child: Text(entry.value, style: bodyTextStyle))]))),
                      const Divider(height: 40),
                      const Text('Komentar', style: headingStyle), const SizedBox(height: 8),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text("Fitur komentar akan segera hadir!", style: metaTextStyle))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractionBottomBar(RecipeModel recipe) {
    return BottomAppBar(
      color: AppColors.white,
      elevation: 10.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _toggleBookmark,
              icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: _isBookmarked ? AppColors.primaryOrange : AppColors.textPrimaryDark, size: 22),
              label: Text(
                "${recipe.bookmarksCount} disimpan",
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
              ),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            Row(
              children: [
                _buildSmallInteractionButton(icon: _isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? AppColors.error : AppColors.greyDark, onTap: _toggleLike),
                _buildSmallInteractionButton(icon: Icons.chat_bubble_outline, color: AppColors.greyDark, onTap: () => CustomOverlayNotification.show(context, 'Fitur komentar akan segera hadir!', isSuccess: false)),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'copy') _copyLink();
                    else if (value == 'share') _shareRecipe();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 20), SizedBox(width: 8), Text('Salin Tautan')])),
                    const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 20), SizedBox(width: 8), Text('Bagikan')])),
                  ],
                  icon: const Icon(Icons.send_outlined, color: AppColors.greyDark, size: 24),
                  tooltip: "Bagikan",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSmallInteractionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}
