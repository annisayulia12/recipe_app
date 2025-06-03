// lib/views/pages/input_page.dart
import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/models/models.dart'; // Impor RecipeModel
import 'package:firebase_auth/firebase_auth.dart'; // Impor User
import 'package:cloud_firestore/cloud_firestore.dart'; // Impor Timestamp

enum PostPrivacy { publik, pribadi }

class InputPage extends StatefulWidget {
  final FirestoreService firestoreService;
  final AuthService authService;

  const InputPage({
    super.key,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaResepController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController(); // Tambahan untuk deskripsi
  final TextEditingController _bahanMasakanController = TextEditingController();
  final TextEditingController _caraMasakController = TextEditingController();

  PostPrivacy _selectedPrivacy = PostPrivacy.publik;
  bool _isLoading = false;
  // TODO: Tambahkan state untuk file gambar jika akan implementasi upload
  // File? _selectedImage;

  @override
  void dispose() {
    _namaResepController.dispose();
    _deskripsiController.dispose();
    _bahanMasakanController.dispose();
    _caraMasakController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), // Tambah padding atas
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    // Menggunakan InputDecorationTheme dari main.dart, namun bisa di-override di sini jika perlu
    // Untuk konsistensi, kita bisa biarkan ThemeData yang mengatur sebagian besar style.
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // Border, enabledBorder, focusedBorder akan diambil dari ThemeData jika tidak di-override di sini
    );
  }

  Widget _buildPrivacyButton(String text, PostPrivacy value) {
    bool isSelected = _selectedPrivacy == value;
    final Color activeColor = AppColors.primaryGreen;
    final Color activeTextColor = AppColors.white;
    final Color inactiveColor = Colors.transparent;
    final Color inactiveTextColor = AppColors.textSecondaryDark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPrivacy = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? activeTextColor : inactiveTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validasi gagal
    }

    setState(() => _isLoading = true);

    User? currentUser = widget.authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan info pengguna. Silakan login ulang.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // TODO: Implementasi upload gambar ke Firebase Storage dan dapatkan URL-nya
    String? imageUrl; // Untuk sekarang null

    // Memecah string bahan dan langkah menjadi list
    // Asumsi pengguna memisahkan tiap item/langkah dengan baris baru
    List<String> ingredientsList = _bahanMasakanController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    List<String> stepsList = _caraMasakController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    RecipeModel newRecipe = RecipeModel(
      id: '', // Firestore akan generate ID
      title: _namaResepController.text.trim(),
      description: _deskripsiController.text.trim().isNotEmpty ? _deskripsiController.text.trim() : null,
      ingredients: ingredientsList,
      steps: stepsList,
      imageUrl: imageUrl, // Akan diisi setelah implementasi upload gambar
      ownerId: currentUser.uid,
      ownerName: currentUser.displayName ?? 'Pengguna Anonim',
      ownerPhotoUrl: currentUser.photoURL,
      createdAt: Timestamp.now(),
      isPublic: _selectedPrivacy == PostPrivacy.publik,
      likesCount: 0,
      commentsCount: 0,
      // updatedAt bisa null saat pembuatan
    );

    try {
      await widget.firestoreService.addRecipe(newRecipe);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resep berhasil diposting!'), backgroundColor: AppColors.success),
      );
      if (mounted) {
        Navigator.of(context).pop(); // Kembali ke halaman sebelumnya setelah sukses
      }
    } catch (e) {
      print("Error posting resep: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memposting resep: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // TODO: Implementasi fungsi _pickImage()
  Future<void> _pickImage() async {
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fungsi pilih gambar belum diimplementasikan.'),
        ),
      );
    // Gunakan package image_picker atau sejenisnya
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() {
    //     _selectedImage = File(image.path);
    //   });
    // }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_circle_left_outlined,
            color: AppColors.primaryOrange,
            size: 30,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tambah Resep',
          style: TextStyle(
            color: AppColors.secondaryTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nama Resep'),
              TextFormField(
                controller: _namaResepController,
                decoration: _inputDecoration('Masukkan nama resep anda'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama resep tidak boleh kosong';
                  }
                  return null;
                },
              ),
              _buildLabel('Deskripsi Singkat (Opsional)'),
              TextFormField(
                controller: _deskripsiController,
                decoration: _inputDecoration('Ceritakan sedikit tentang resepmu'),
                maxLines: 2,
                // Tidak ada validator karena opsional
              ),
              _buildLabel('Foto Masakan'),
              GestureDetector(
                onTap: _pickImage, // Panggil fungsi pilih gambar
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    // TODO: Tampilkan _selectedImage jika ada
                  ),
                  // child: _selectedImage != null
                  // ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  // : Column( // Tampilan placeholder jika gambar belum dipilih
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 50,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan foto masakan anda',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              _buildLabel('Bahan Masakan (pisahkan per baris)'),
              TextFormField(
                controller: _bahanMasakanController,
                decoration: _inputDecoration('Contoh:\n1 siung bawang putih\n2 sdm kecap manis'),
                maxLines: 5, // Lebih banyak baris untuk bahan
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bahan masakan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              _buildLabel('Cara Masak (pisahkan per langkah/baris)'),
              TextFormField(
                controller: _caraMasakController,
                decoration: _inputDecoration('Contoh:\n1. Panaskan minyak.\n2. Tumis bumbu...'),
                maxLines: 7, // Lebih banyak baris untuk cara masak
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cara masak tidak boleh kosong';
                  }
                  return null;
                },
              ),
              _buildLabel('Atur postingan sebagai'),
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: AppColors.privacySwitchBackground,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    _buildPrivacyButton('Publik', PostPrivacy.publik),
                    _buildPrivacyButton('Pribadi', PostPrivacy.pribadi),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Posting Resep',
                          style: TextStyle(color: AppColors.white),
                        ),
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
