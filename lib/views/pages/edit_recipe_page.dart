// lib/views/pages/edit_recipe_page.dart
import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum PostPrivacy bisa dipindahkan ke file sendiri jika digunakan di banyak tempat
enum PostPrivacy { publik, pribadi }

class EditRecipePage extends StatefulWidget {
  final RecipeModel initialRecipe; // Terima resep yang akan diedit
  final FirestoreService firestoreService;
  final AuthService authService;

  const EditRecipePage({
    super.key,
    required this.initialRecipe,
    required this.firestoreService,
    required this.authService,
  });

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaResepController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _bahanMasakanController;
  late final TextEditingController _caraMasakController;

  late PostPrivacy _selectedPrivacy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data resep yang ada
    _namaResepController = TextEditingController(text: widget.initialRecipe.title);
    _deskripsiController = TextEditingController(text: widget.initialRecipe.description ?? '');
    _bahanMasakanController = TextEditingController(text: widget.initialRecipe.ingredients.join('\n'));
    _caraMasakController = TextEditingController(text: widget.initialRecipe.steps.join('\n'));
    _selectedPrivacy = widget.initialRecipe.isPublic ? PostPrivacy.publik : PostPrivacy.pribadi;
  }

  @override
  void dispose() {
    _namaResepController.dispose();
    _deskripsiController.dispose();
    _bahanMasakanController.dispose();
    _caraMasakController.dispose();
    super.dispose();
  }

  // Metode _buildLabel, _inputDecoration, _buildPrivacyButton sama seperti di InputPage
  // (Anda bisa menyalinnya dari kode InputPage sebelumnya)
   Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
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

  Widget _buildPrivacyButton(String text, PostPrivacy value) {
    bool isSelected = _selectedPrivacy == value;
    final Color activeColor = AppColors.primaryGreen;
    final Color activeTextColor = AppColors.white;
    final Color inactiveColor = Colors.transparent;
    final Color inactiveTextColor = AppColors.textSecondaryDark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() { _selectedPrivacy = value; });
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

  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: Implementasi upload gambar baru jika ada
    String? imageUrl = widget.initialRecipe.imageUrl;

    List<String> ingredientsList = _bahanMasakanController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    List<String> stepsList = _caraMasakController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

    // Gunakan copyWith untuk membuat objek baru dengan data yang diperbarui
    RecipeModel updatedRecipe = widget.initialRecipe.copyWith(
      title: _namaResepController.text.trim(),
      description: _deskripsiController.text.trim().isNotEmpty ? _deskripsiController.text.trim() : null,
      ingredients: ingredientsList,
      steps: stepsList,
      imageUrl: imageUrl, // Gunakan URL gambar baru jika ada
      isPublic: _selectedPrivacy == PostPrivacy.publik,
      updatedAt: Timestamp.now(), // Tandai waktu pembaruan
    );

    try {
      await widget.firestoreService.updateRecipe(updatedRecipe);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resep berhasil diperbarui!'), backgroundColor: AppColors.success),
      );
      if (mounted) {
        // Kirim 'true' kembali untuk menandakan ada perubahan
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui resep: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Resep', style: TextStyle(color: AppColors.secondaryTeal, fontWeight: FontWeight.bold)),
        // ... (sisa AppBar sama seperti InputPage) ...
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.white, elevation: 1, centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (UI Form sama seperti InputPage, tapi menggunakan controller yang sudah diisi) ...
              _buildLabel('Nama Resep'),
              TextFormField(
                controller: _namaResepController,
                decoration: const InputDecoration(hintText: 'Masukkan nama resep anda'),
                validator: (v) => (v == null || v.isEmpty) ? 'Nama resep tidak boleh kosong' : null,
              ),

              _buildLabel('Deskripsi Singkat (Opsional)'),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(hintText: 'Ceritakan sedikit tentang resepmu'),
                maxLines: 2,
              ),

              _buildLabel('Foto Masakan'),
              // TODO: Implementasi UI untuk menampilkan gambar yang ada dan opsi untuk mengubahnya

              _buildLabel('Bahan Masakan (pisahkan per baris)'),
              TextFormField(
                controller: _bahanMasakanController,
                decoration: const InputDecoration(hintText: 'Contoh:\n1 siung bawang putih...'),
                maxLines: 5,
                validator: (v) => (v == null || v.isEmpty) ? 'Bahan masakan tidak boleh kosong' : null,
              ),

              _buildLabel('Cara Masak (pisahkan per langkah/baris)'),
              TextFormField(
                controller: _caraMasakController,
                decoration: const InputDecoration(hintText: 'Contoh:\n1. Panaskan minyak...'),
                maxLines: 7,
                validator: (v) => (v == null || v.isEmpty) ? 'Cara masak tidak boleh kosong' : null,
              ),

              _buildLabel('Atur postingan sebagai'),
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: AppColors.privacySwitchBackground,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(children: [
                  _buildPrivacyButton('Publik', PostPrivacy.publik),
                  _buildPrivacyButton('Pribadi', PostPrivacy.pribadi),
                ]),
              ),

              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateRecipe, // Panggil fungsi update
                        child: const Text('Simpan Perubahan', style: TextStyle(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
