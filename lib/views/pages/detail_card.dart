import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/views/pages/edit_recipe_page.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final String _dynamicLinkDomain = "recipeinapp.page.link";

  @override
  void initState() {
    super.initState();
    _currentUser = widget.authService.getCurrentUser();
    _detailsFuture = _loadRecipeDetails();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
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
  
  void _postComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null || _recipe == null) return;
    final commentText = _commentController.text.trim();
    _commentController.clear();
    _commentFocusNode.unfocus();
    final newComment = CommentModel(
      id: '', recipeId: _recipe!.id, userId: _currentUser!.uid,
      userName: _currentUser!.displayName ?? 'Anonim', userPhotoUrl: _currentUser!.photoURL,
      text: commentText, createdAt: Timestamp.now(),
    );
    try {
      await widget.interactionService.addComment(newComment, _recipe!, _currentUser!);
    } catch (e) {
      if(mounted) CustomOverlayNotification.show(context, 'Gagal mengirim komentar.', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecipeDetailBundle?>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: const Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: Center(child: Text("Error: ${snapshot.error}")));
        if (!snapshot.hasData || snapshot.data == null) return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: const Center(child: Text('Resep tidak ditemukan.')));

        if (_recipe == null) {
          _recipe = snapshot.data!.recipe;
          _isLiked = snapshot.data!.isLiked;
          _isBookmarked = snapshot.data!.isBookmarked;
        }
        
        final recipeData = _recipe!;
        final bool isOwner = _currentUser?.uid == recipeData.ownerId;

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: _buildAppBar(recipeData, isOwner),
          bottomNavigationBar: _buildCommentInputField(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecipeHeader(recipeData),
                _buildInteractionRow(recipeData),
                _buildRecipeInfoSection(recipeData),
                _buildCommentSection(recipeData.id),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Widget & Metode Helper ---

  AppBar _buildAppBar(RecipeModel recipeData, bool isOwner) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30), onPressed: () => Navigator.of(context).pop()),
      backgroundColor: AppColors.white,
      elevation: 1,
      title: Row(children: [
        CircleAvatar(radius: 18, backgroundImage: recipeData.ownerPhotoUrl != null && recipeData.ownerPhotoUrl!.isNotEmpty ? NetworkImage(recipeData.ownerPhotoUrl!) : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider),
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
    );
  }

  Widget _buildRecipeHeader(RecipeModel recipeData) {
    const metaTextStyle = TextStyle(fontSize: 12, color: AppColors.greyMedium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipeData.imageUrl != null && recipeData.imageUrl!.isNotEmpty)
          Image.network(recipeData.imageUrl!, width: double.infinity, height: 250, fit: BoxFit.cover)
        else
          Container(width: double.infinity, height: 250, color: AppColors.greyLight, child: const Icon(Icons.restaurant_menu, size: 60)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recipeData.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
              const SizedBox(height: 4),
              Text("Diposting pada ${recipeData.createdAt.toDate().toString().substring(0, 10)}", style: metaTextStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionRow(RecipeModel recipe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _toggleBookmark,
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: _isBookmarked ? AppColors.primaryOrange : AppColors.textPrimaryDark, size: 22),
            label: Text("${recipe.bookmarksCount} disimpan", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          Row(
            children: [
              IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? AppColors.error : AppColors.greyDark), onPressed: _toggleLike),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, color: AppColors.greyDark), onPressed: () => _commentFocusNode.requestFocus()),
              IconButton(icon: const Icon(Icons.send_outlined, color: AppColors.greyDark), onPressed: _shareRecipe),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeInfoSection(RecipeModel recipe) {
    const headingStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark);
    const bodyTextStyle = TextStyle(fontSize: 14, color: AppColors.textSecondaryDark, height: 1.5);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
            const Text('Deskripsi', style: headingStyle),
            const SizedBox(height: 8),
            Text(recipe.description!, style: bodyTextStyle),
            const Divider(height: 32),
          ],
          const Text('Bahan-bahan', style: headingStyle), const SizedBox(height: 8),
          if (recipe.ingredients.isEmpty) const Text("Tidak ada bahan yang dicantumkan.") else ...recipe.ingredients.map((val) => Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text('• $val', style: bodyTextStyle))),
          const SizedBox(height: 24),
          const Text('Langkah-langkah', style: headingStyle), const SizedBox(height: 8),
          if (recipe.steps.isEmpty) const Text("Tidak ada langkah-langkah yang dicantumkan.") else ...recipe.steps.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${entry.key + 1}. ', style: bodyTextStyle.copyWith(fontWeight: FontWeight.bold)), Expanded(child: Text(entry.value, style: bodyTextStyle))]))),
        ],
      ),
    );
  }
  
  Widget _buildCommentSection(String recipeId) {
    const headingStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Komentar', style: headingStyle),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<CommentModel>>(
          stream: widget.interactionService.getComments(recipeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text("Jadilah yang pertama berkomentar!", style: TextStyle(color: AppColors.greyMedium))));
            final comments = snapshot.data!;
            return ListView.builder(
              itemCount: comments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) => CommentTile(comment: comments[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions_outlined, color: AppColors.greyMedium),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _commentController, focusNode: _commentFocusNode, decoration: const InputDecoration.collapsed(hintText: 'Ekspresikan idemu disini...'), textCapitalization: TextCapitalization.sentences)),
          IconButton(icon: const Icon(Icons.send, color: AppColors.primaryOrange), onPressed: _postComment),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  const CommentTile({super.key, required this.comment});
  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('id', timeago.IdMessages());
    final String timeAgo = timeago.format(comment.createdAt.toDate(), locale: 'id');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 20, backgroundImage: comment.userPhotoUrl != null && comment.userPhotoUrl!.isNotEmpty ? NetworkImage(comment.userPhotoUrl!) : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(timeAgo, style: const TextStyle(color: AppColors.greyMedium, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Text(comment.text, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Balas', style: TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Column(children: [
            const Icon(Icons.favorite_border, color: AppColors.greyMedium, size: 18),
            Text(comment.likesCount.toString(), style: const TextStyle(fontSize: 12)),
          ])
        ],
      ),
    );
  }
}
