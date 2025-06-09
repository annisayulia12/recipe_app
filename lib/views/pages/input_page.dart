// lib/views/pages/input_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/services/storage_service.dart'; // Import Storage
import 'package:recipein_app/widgets/custom_overlay_notification.dart';

class InputPage extends StatefulWidget {
  final RecipeService recipeService;
  final AuthService authService;
  final RecipeModel? recipeToEdit; // Tambahkan ini untuk mode edit

  const InputPage({
    super.key,
    required this.recipeService,
    required this.authService,
    this.recipeToEdit, // Jadikan opsional
  });

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _namaResepController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _bahanMasakanController = TextEditingController();
  final TextEditingController _caraMasakController = TextEditingController();

  // State
  PostPrivacy _selectedPrivacy = PostPrivacy.publik;
  bool _isLoading = false;
  bool _isFormDirty = false;
  File? _selectedImageFile; // Untuk menyimpan file gambar yang dipilih
  String? _existingImageUrl; // Untuk menyimpan URL gambar yang sudah ada (saat edit)

  // Cek apakah ini mode edit
  bool get _isEditMode => widget.recipeToEdit != null;

  @override
  void initState() {
    super.initState();
    // Jika ini mode edit, isi form dengan data yang ada
    if (_isEditMode) {
      _populateFieldsForEdit();
    }
    // Tambahkan listener untuk mendeteksi perubahan input
    _namaResepController.addListener(_setFormDirty);
    _deskripsiController.addListener(_setFormDirty);
    _bahanMasakanController.addListener(_setFormDirty);
    _caraMasakController.addListener(_setFormDirty);
  }

  void _populateFieldsForEdit() {
    final recipe = widget.recipeToEdit!;
    _namaResepController.text = recipe.title;
    _deskripsiController.text = recipe.description ?? '';
    _bahanMasakanController.text = recipe.ingredients.join('\n');
    _caraMasakController.text = recipe.steps.join('\n');
    _selectedPrivacy = recipe.isPublic ? PostPrivacy.publik : PostPrivacy.pribadi;
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
      _existingImageUrl = recipe.imageUrl;
    }
  }

  void _setFormDirty() {
    if (!_isFormDirty) {
      setState(() {
        _isFormDirty = true;
      });
    }
  }

  @override
  void dispose() {
    _namaResepController.removeListener(_setFormDirty);
    _deskripsiController.removeListener(_setFormDirty);
    _bahanMasakanController.removeListener(_setFormDirty);
    _caraMasakController.removeListener(_setFormDirty);
    _namaResepController.dispose();
    _deskripsiController.dispose();
    _bahanMasakanController.dispose();
    _caraMasakController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // ... (Fungsi _onWillPop tidak berubah) ...
    return true;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Kompresi gambar untuk menghemat ukuran
      maxWidth: 1080,   // Batasi lebar gambar
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isFormDirty = true; // Memilih gambar dianggap sebagai perubahan
      });
    }
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    User? currentUser = widget.authService.getCurrentUser();
    if (currentUser == null) {
      CustomOverlayNotification.show(context, 'Gagal mendapatkan info pengguna. Silakan login ulang.', isSuccess: false);
      setState(() => _isLoading = false);
      return;
    }

    String? imageUrl = _existingImageUrl; // Mulai dengan URL yang ada (jika ada)

    try {
      // 1. Jika ada file gambar baru yang dipilih, unggah
      if (_selectedImageFile != null) {
        // Jika ini mode edit dan ada gambar lama, hapus gambar lama dulu
        if (_isEditMode && _existingImageUrl != null) {
          await _storageService.deleteFile(_existingImageUrl!);
        }

        // Buat path yang unik untuk gambar baru
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = 'recipe_images/${currentUser.uid}/$timestamp.jpg';
        
        // Unggah gambar baru dan dapatkan URL-nya
        imageUrl = await _storageService.uploadFile(_selectedImageFile!, path);
      }

      // 2. Siapkan model resep dengan data dari form
      List<String> ingredientsList = _bahanMasakanController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
      List<String> stepsList = _caraMasakController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

      RecipeModel recipeData = RecipeModel(
        id: _isEditMode ? widget.recipeToEdit!.id : '', // Gunakan ID lama jika edit
        title: _namaResepController.text.trim(),
        description: _deskripsiController.text.trim(),
        ingredients: ingredientsList,
        steps: stepsList,
        imageUrl: imageUrl, // Gunakan URL gambar baru atau yang lama
        ownerId: currentUser.uid,
        ownerName: currentUser.displayName ?? 'Pengguna Anonim',
        ownerPhotoUrl: currentUser.photoURL,
        createdAt: _isEditMode ? widget.recipeToEdit!.createdAt : Timestamp.now(), // Gunakan timestamp lama jika edit
        updatedAt: Timestamp.now(), // Selalu perbarui timestamp ini
        isPublic: _selectedPrivacy == PostPrivacy.publik,
      );

      // 3. Simpan ke Firestore (update atau add baru)
      if (_isEditMode) {
        await widget.recipeService.updateRecipe(recipeData);
      } else {
        await widget.recipeService.addRecipe(recipeData);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Keluar dari halaman input
        Future.delayed(const Duration(milliseconds: 200), () {
          CustomOverlayNotification.show(context, _isEditMode ? 'Resep berhasil diperbarui' : 'Resep berhasil diposting');
        });
      }

    } catch (e) {
      if(mounted) CustomOverlayNotification.show(context, 'Terjadi kegagalan: ${e.toString()}', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePicker() {
    // UI untuk memilih gambar
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tampilan Gambar
            if (_selectedImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  _selectedImageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else if (_existingImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  _existingImageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  // Tampilkan loading indicator saat gambar network dimuat
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                     return const Icon(Icons.broken_image_outlined, size: 50, color: AppColors.error);
                  },
                ),
              )
            else
              // Tampilan Placeholder
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text('Masukkan foto masakan anda', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            
            // Tombol Edit Overlay
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      (_selectedImageFile != null || _existingImageUrl != null) ? 'Ganti Foto' : 'Pilih Foto',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _isEditMode ? 'Edit Resep' : 'Tambah Resep', 
            style: const TextStyle(color: AppColors.secondaryTeal, fontWeight: FontWeight.bold)
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
                 _buildLabel('Foto Masakan'),
                 _buildImagePicker(), // Gunakan widget baru
                
                // ... (Field form lainnya tidak berubah) ...
                 _buildLabel('Nama Resep'),
                TextFormField(
                  controller: _namaResepController,
                  decoration: const InputDecoration(hintText: 'Masukkan nama resep anda'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama resep tidak boleh kosong' : null,
                ),
                _buildLabel('Deskripsi Singkat (Opsional)'),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(hintText: 'Ceritakan sedikit tentang resepmu'),
                  maxLines: 2,
                ),
                _buildLabel('Bahan Masakan (pisahkan per baris)'),
                TextFormField(
                  controller: _bahanMasakanController,
                  decoration: const InputDecoration(hintText: 'Contoh:\n1 siung bawang putih\n2 sdm kecap manis'),
                  maxLines: 5,
                  validator: (value) => (value == null || value.isEmpty) ? 'Bahan masakan tidak boleh kosong' : null,
                ),
                _buildLabel('Cara Masak (pisahkan per langkah/baris)'),
                TextFormField(
                  controller: _caraMasakController,
                  decoration: const InputDecoration(hintText: 'Contoh:\n1. Panaskan minyak.\n2. Tumis bumbu...'),
                  maxLines: 7,
                  validator: (value) => (value == null || value.isEmpty) ? 'Cara masak tidak boleh kosong' : null,
                ),
                _buildLabel('Atur postingan sebagai'),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(color: AppColors.privacySwitchBackground, borderRadius: BorderRadius.circular(10.0)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: Text(
                            _isEditMode ? 'Simpan Perubahan' : 'Posting Resep',
                            style: const TextStyle(color: AppColors.white)
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Fungsi _buildLabel dan _buildPrivacyButton tetap sama
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), child: Text(text, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 14)));
  Widget _buildPrivacyButton(String text, PostPrivacy value) {
    bool isSelected = _selectedPrivacy == value;
    return Expanded(child: GestureDetector(onTap: () { _setFormDirty(); setState(() { _selectedPrivacy = value; }); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 10.0), decoration: BoxDecoration(color: isSelected ? AppColors.primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(8.0)), alignment: Alignment.center, child: Text(text, style: TextStyle(color: isSelected ? AppColors.white : AppColors.textSecondaryDark, fontWeight: FontWeight.w600)))));
  }
}