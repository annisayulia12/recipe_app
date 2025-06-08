import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/notification_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/views/pages/detail_card.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  final NotificationService notificationService;
  final AuthService authService;
  final RecipeService recipeService;
  final InteractionService interactionService;
  
  const NotificationPage({
    super.key, 
    required this.notificationService, 
    required this.authService, 
    required this.recipeService, 
    required this.interactionService
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.authService.getCurrentUser()?.uid;
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  void _navigateToRecipe(String recipeId) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailCard(
      recipeId: recipeId,
      authService: widget.authService,
      recipeService: widget.recipeService,
      interactionService: widget.interactionService,
    )));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(appBar: AppBar(title: const Text('Notifikasi')), body: const Center(child: Text('Silakan login untuk melihat notifikasi.')));
    }
    
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white, elevation: 1, centerTitle: true,
        title: const Text('Notifikasi', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 20)),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: widget.notificationService.getUserNotifications(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat notifikasi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada notifikasi baru.', style: TextStyle(color: AppColors.greyMedium)));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return NotificationTile(
                notification: notifications[index],
                onTap: () => _navigateToRecipe(notifications[index].recipeId),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const NotificationTile({super.key, required this.notification, required this.onTap});

  String _buildNotificationText() {
    switch (notification.type) {
      case 'like': return 'menyukai postingan anda.';
      case 'comment': return 'mengomentari postingan anda:';
      case 'reply': return 'membalas anda pada postingannya:';
      case 'bookmark': return 'menyimpan postingan anda.';
      default: return 'berinteraksi dengan postingan anda.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String timeAgo = timeago.format(notification.createdAt.toDate(), locale: 'id');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: notification.isRead ? Colors.transparent : AppColors.primaryOrange.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: notification.actorPhotoUrl != null && notification.actorPhotoUrl!.isNotEmpty
                ? NetworkImage(notification.actorPhotoUrl!)
                : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimaryDark),
                      children: [
                        TextSpan(text: notification.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' ${_buildNotificationText()}', style: const TextStyle(color: AppColors.textSecondaryDark)),
                      ]
                    ),
                  ),
                  if (notification.type == 'comment' && notification.commentText != null && notification.commentText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '"${notification.commentText!}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.greyDark, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.greyMedium)),
                ],
              )
            ),
            const SizedBox(width: 12),
            if (notification.recipeImageUrl != null && notification.recipeImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(notification.recipeImageUrl!, width: 50, height: 50, fit: BoxFit.cover),
              )
          ],
        ),
      ),
    );
  }
}
