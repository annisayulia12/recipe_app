import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/views/pages/edit_recipe_page.dart';

class DetailCard extends StatelessWidget {
  const DetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final String recipeName = 'Chicken Teriyaki';
    final String postDate = 'Diposting 3 Januari 2025';
    final String recipeImageUrl = 'assets/images/image2.png';
    final String userAvatarUrl = 'assets/images/profile3.png';
    final String userName = 'Tiara Vania';

    final List<String> ingredients = [
      '500 gr dada ayam filet',
      '2 sdm saos tiram',
      '2 sdm kecap manis',
      '1 sdm kecap asin',
      '1 sdm minyak wijen',
      '1 sdm kecap inggris',
      '1 ruas jahe',
      '3 buah bawang putih',
      '1 buah bawang bombay',
      'Secukupnya garam, penyedap, gula, lada',
    ];

    final List<String> steps = [
      '1. Siapkan semua bahan.',
      '2. Potong dada ayam filet menjadi ukuran sesuai selera.',
      '3. Campurkan saos tiram, kecap manis, kecap asin, minyak wijen, dan kecap inggris dalam mangkuk.',
      '4. Tambahkan parutan jahe, bawang putih cincang, dan bawang bombay iris ke dalam campuran saus.',
      '5. Lumuri ayam dengan bumbu, diamkan minimal 30 menit.',
      '6. Panaskan sedikit minyak, masak ayam hingga matang dan saus mengental.',
      '7. Sesuaikan rasa dengan garam, penyedap, gula, dan lada.',
      '8. Sajikan Chicken Teriyaki dengan nasi hangat.',
    ];

    final List<Map<String, dynamic>> comments = [
      {
        'avatarUrl': 'assets/images/profile4.png',
        'name': 'Ara',
        'comment': 'Enak dan mudah dibuat, resep ini sangat membantu saya!',
        'date': '11/05/2025',
        'likes': 10,
      },
      {
        'avatarUrl': 'assets/images/profile5.png',
        'name': 'Budi',
        'comment':
            'Saya coba resep ini dan hasilnya luar biasa, terima kasih Tiara!',
        'date': '12/05/2025',
        'likes': 5,
      },
      {
        'avatarUrl': 'assets/images/profile6.png',
        'name': 'Citra',
        'comment': 'Apakah bisa pakai paha ayam?',
        'date': '13/05/2025',
        'likes': 3,
      },
    ];
    const TextStyle headingStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    );
    const TextStyle bodyTextStyle = TextStyle(
      fontSize: 14,
      color: AppColors.textSecondaryDark,
      height: 1.5,
    );
    const TextStyle metaTextStyle = TextStyle(
      fontSize: 12,
      color: AppColors.greyMedium,
    );
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_circle_left_outlined,
                            color: AppColors.primaryOrange,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Avatar Pengguna
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(userAvatarUrl),
                      onBackgroundImageError: (exception, stackTrace) {
                        //print
                        ('Error memuat gambar avatar pengguna: $exception');
                      },
                    ),
                    const SizedBox(width: 12),

                    // Nama Pengguna
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.greyMedium,
                        size: 28,
                      ),
                      onSelected: (String result) {
                        if (result == 'edit') {
                          final Map<String, dynamic> currentRecipeData = {
                            'recipeName': recipeName,
                            'ingredients': ingredients,
                            'steps': steps,
                            'privacy': 'publik',
                            'recipeImageUrl': recipeImageUrl,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditRecipePage(
                                    recipeData: currentRecipeData,
                                  ),
                            ),
                          );
                        } else if (result == 'delete') {
                          //print
                          ('Hapus Postingan ditekan!');
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: const Text(
                                  'Apakah Anda yakin ingin menghapus resep ini?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      //print
                                      ('Resep dihapus!');
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(); // Tutup dialog
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit Postingan',
                                    style: TextStyle(
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hapus Postingan',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                  ],
                ),
              ),
              // Gambar Resep
              Image.asset(
                recipeImageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: AppColors.greyLight,
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: AppColors.greyMedium,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Judul Resep dan Tanggal Posting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(postDate, style: metaTextStyle),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ikon Interaksi (Like, Comment, Bookmark, Share)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Ikon Like
                        IconButton(
                          icon: Icon(
                            Icons.favorite_border,
                            color: AppColors.greyMedium,
                            size: 24,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        // Ikon Komentar
                        IconButton(
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.greyMedium,
                            size: 24,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        // Ikon Bookmark
                        IconButton(
                          icon: Icon(
                            Icons.bookmark_border,
                            color: AppColors.greyMedium,
                            size: 24,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: AppColors.greyMedium,
                        size: 24,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bahan-bahan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bahan-bahan', style: headingStyle),
                    const SizedBox(height: 8),
                    ...ingredients.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      String val = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('$idx. $val', style: bodyTextStyle),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Langkah-langkah
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Langkah-langkah', style: headingStyle),
                    const SizedBox(height: 8),
                    ...steps.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      String val = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('$idx. $val', style: bodyTextStyle),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Komentar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Komentar', style: headingStyle),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage(comment['avatarUrl']),
                          onBackgroundImageError: (exception, stackTrace) {
                            //print
                            (
                              'Error memuat gambar avatar komentator: $exception',
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment['comment'],
                                style: bodyTextStyle.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    comment['date'],
                                    style: metaTextStyle.copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      // Aksi untuk balas komentar
                                    },
                                    child: Text(
                                      'Balas',
                                      style: metaTextStyle.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.greyDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              comment['likes'].toString(),
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 18.0 + 12.0),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat 2 balasan lainnya',
                            style: metaTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.greyDark,
                              fontSize: 12,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.greyDark,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
