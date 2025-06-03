import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data notifikasi placeholder
    final List<Map<String, dynamic>> notifications = [
      {
        'avatarUrl': 'assets/images/profile1.png',
        'userName': 'Tiara Vania',
        'action': 'telah memposting resep baru',
        'date': '2 jam lalu',
      },
      {
        'avatarUrl': 'assets/images/profile2.png',
        'userName': 'Budi Santoso',
        'action': 'menukai resep Anda',
        'date': 'Kemarin',
      },
      {
        'avatarUrl': 'assets/images/profile3.png',
        'userName': 'Citra Dewi',
        'action': 'mengomentari resep Anda',
        'date': '3 hari lalu',
      },
      {
        'avatarUrl': 'assets/images/profile4.png',
        'userName': 'Dian Pertiwi',
        'action': 'mulai mengikuti Anda',
        'date': '1 minggu lalu',
      },
      {
        'avatarUrl': 'assets/images/profile5.png',
        'userName': 'Eka Putra',
        'action': 'telah memposting resep baru',
        'date': '2 minggu lalu',
      },
      {
        'avatarUrl': 'assets/images/profile5.png',
        'userName': 'Farida',
        'action': 'mengomentari resep Anda',
        'date': '3 minggu lalu',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          'Notifikasi',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 20),

            // Daftar Notifikasi
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Pengguna
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                            notification['avatarUrl'],
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            //print
                            ('Error memuat gambar avatar: $exception');
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: notification['userName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimaryDark,
                                        fontSize: 15,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${notification['action']}',
                                      style: TextStyle(
                                        color: AppColors.textSecondaryDark,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Tanggal Notifikasi
                              Text(
                                notification['date'],
                                style: TextStyle(
                                  color: AppColors.greyMedium,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
