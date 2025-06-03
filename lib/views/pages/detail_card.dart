import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/models/models.dart'; // Impor model jika akan menampilkan data dinamis
import 'package:recipein_app/services/firestore_service.dart'; // Impor FirestoreService

class DetailCard extends StatefulWidget {
  final String recipeId;
  final FirestoreService firestoreService; // Pastikan ini ada dan required

  const DetailCard({
    super.key,
    required this.recipeId,
    required this.firestoreService, // Pastikan ini ada dan required
  });

  @override
  State<DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends State<DetailCard> {
  RecipeModel? _recipe; // Untuk menyimpan data resep yang diambil
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recipeData = await widget.firestoreService.getRecipe(widget.recipeId);
      if (mounted) {
        setState(() {
          _recipe = recipeData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat detail resep: ${e.toString()}";
          _isLoading = false;
        });
      }
      print("Error fetching recipe details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 16)),
          ),
        ),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text("Resep tidak ditemukan.", style: TextStyle(fontSize: 16, color: AppColors.greyDark)),
        ),
      );
    }

    // Gunakan data dari _recipe untuk membangun UI
    final recipeData = _recipe!;
    final String recipeName = recipeData.title;
    final String postDate = recipeData.createdAt.toDate().toString().substring(0,10); // Format tanggal sederhana
    final String? recipeImageUrl = recipeData.imageUrl;
    final String? userAvatarUrl = recipeData.ownerPhotoUrl;
    final String userName = recipeData.ownerName;
    final List<String> ingredients = recipeData.ingredients;
    final List<String> steps = recipeData.steps;
    // TODO: Implementasi pengambilan dan tampilan komentar dinamis

    const TextStyle headingStyle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark,
    );
    const TextStyle bodyTextStyle = TextStyle(
      fontSize: 14, color: AppColors.textSecondaryDark, height: 1.5,
    );
    const TextStyle metaTextStyle = TextStyle(
      fontSize: 12, color: AppColors.greyMedium,
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
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Center(
                          child: Icon(
                            Icons.arrow_circle_left_outlined,
                            color: AppColors.primaryOrange,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: userAvatarUrl != null && userAvatarUrl.isNotEmpty
                          ? NetworkImage(userAvatarUrl)
                          : const AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                       onBackgroundImageError: (_,__){},
                    ),
                    const SizedBox(width: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (recipeImageUrl != null && recipeImageUrl.isNotEmpty)
                Image.network(
                  recipeImageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(height: 250, color: AppColors.greyLight, child: const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: AppColors.greyLight,
                      child: const Icon(
                        Icons.broken_image, size: 50, color: AppColors.greyMedium,
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  height: 250,
                  color: AppColors.greyLight,
                  child: const Icon(Icons.restaurant_menu, size: 60, color: AppColors.greyMedium),
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Diposting pada $postDate", style: metaTextStyle),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Ikon Interaksi (akan diimplementasikan nanti)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: Icon(Icons.favorite_border, color: AppColors.greyMedium, size: 24), onPressed: () {/* TODO */}),
                        const SizedBox(width: 8),
                        IconButton(icon: Icon(Icons.chat_bubble_outline, color: AppColors.greyMedium, size: 24), onPressed: () {/* TODO */}),
                        const SizedBox(width: 8),
                        IconButton(icon: Icon(Icons.bookmark_border, color: AppColors.greyMedium, size: 24), onPressed: () {/* TODO */}),
                      ],
                    ),
                    IconButton(icon: Icon(Icons.share, color: AppColors.greyMedium, size: 24), onPressed: () {/* TODO */}),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bahan-bahan', style: headingStyle),
                    const SizedBox(height: 8),
                    if (ingredients.isEmpty)
                      const Text("Tidak ada bahan yang dicantumkan.", style: bodyTextStyle)
                    else
                      ...ingredients.map((val) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text('• $val', style: bodyTextStyle),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Langkah-langkah', style: headingStyle),
                    const SizedBox(height: 8),
                     if (steps.isEmpty)
                      const Text("Tidak ada langkah-langkah yang dicantumkan.", style: bodyTextStyle)
                    else
                      ...steps.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Text('${entry.key + 1}. ${entry.value}', style: bodyTextStyle),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Komentar', style: headingStyle),
              ),
              const SizedBox(height: 8),
              // TODO: Implementasi daftar komentar dinamis
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Center(child: Text("Fitur komentar akan segera hadir!", style: metaTextStyle)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
