import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentSection extends StatefulWidget {
  final String recipeId;
  final RecipeModel recipe;
  final InteractionService interactionService;
  final User? currentUser;

  const CommentSection({
    super.key,
    required this.recipeId,
    required this.recipe,
    required this.interactionService,
    required this.currentUser,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _postComment() async {
    if (_commentController.text.trim().isEmpty || widget.currentUser == null) return;
    
    final commentText = _commentController.text.trim();
    _commentController.clear();
    _commentFocusNode.unfocus();
    
    final newComment = CommentModel(
      id: '', recipeId: widget.recipeId, userId: widget.currentUser!.uid,
      userName: widget.currentUser!.displayName ?? 'Anonim',
      userPhotoUrl: widget.currentUser!.photoURL,
      text: commentText, createdAt: Timestamp.now(),
    );

    try {
      await widget.interactionService.addComment(newComment, widget.recipe, widget.currentUser!);
    } catch (e) {
      if(mounted) CustomOverlayNotification.show(context, 'Gagal mengirim komentar.', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          stream: widget.interactionService.getComments(widget.recipeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text("Jadilah yang pertama berkomentar!")));
            final comments = snapshot.data!;
            return ListView.builder(
              itemCount: comments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => CommentTile(comment: comments[index]),
            );
          },
        ),
      ],
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
          CircleAvatar(radius: 18, backgroundImage: comment.userPhotoUrl != null && comment.userPhotoUrl!.isNotEmpty ? NetworkImage(comment.userPhotoUrl!) : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider),
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
                  onPressed: () { /* TODO: Implementasi balas */ },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Balas', style: TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Column(children: [const Icon(Icons.favorite_border, color: AppColors.greyMedium, size: 18), Text(comment.likesCount.toString(), style: const TextStyle(fontSize: 12))])
        ],
      ),
    );
  }
}