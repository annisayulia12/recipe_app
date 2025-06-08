import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart'; // Impor notifikasi kustom yang baru
class InputPage extends StatefulWidget {
  final RecipeService recipeService;
  final AuthService authService;

  const InputPage({
    super.key,
    required this.recipeService,
    required this.authService,
  });

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaResepController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _bahanMasakanController = TextEditingController();
  final TextEditingController _caraMasakController = TextEditingController();

  PostPrivacy _selectedPrivacy = PostPrivacy.publik;
  bool _isLoading = false;
  bool _isFormDirty = false; // State baru untuk melacak perubahan

  // TODO: Tambahkan state untuk file gambar jika akan implementasi upload
  // File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Tambahkan listener untuk mendeteksi perubahan input
    _namaResepController.addListener(_setFormDirty);
    _deskripsiController.addListener(_setFormDirty);
    _bahanMasakanController.addListener(_setFormDirty);
    _caraMasakController.addListener(_setFormDirty);
  }

  void _setFormDirty() {
    // Hanya set state sekali untuk efisiensi
    if (!_isFormDirty) {
      setState(() {
        _isFormDirty = true;
      });
    }
  }

  @override
  void dispose() {
    // Hapus listener untuk mencegah memory leak
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

  // --- Fitur 3: Dialog Konfirmasi Keluar ---
  Future<bool> _onWillPop() async {
    if (!_isFormDirty) {
      return true; // Izinkan keluar jika tidak ada perubahan
    }
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 40),
        title: const Text('Keluar dari halaman?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Perubahan yang Anda lakukan mungkin belum disimpan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
        actions: <Widget>[
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false), // Tetap di halaman
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Batal'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Izinkan keluar
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false; // Jika dialog ditutup (misal dengan back button), anggap batal
  }

  // Helper widget tetap sama
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
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _setFormDirty(); // Tandai ada perubahan saat privasi diubah
          setState(() {
            _selectedPrivacy = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textSecondaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // --- Fitur 1: Menggunakan Notifikasi Kustom ---
  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    User? currentUser = widget.authService.getCurrentUser();
    if (currentUser == null) {
      CustomOverlayNotification.show(context, 'Gagal mendapatkan info pengguna. Silakan login ulang.', isSuccess: false);
      setState(() => _isLoading = false);
      return;
    }

    String? imageUrl; // Placeholder
    List<String> ingredientsList = _bahanMasakanController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    List<String> stepsList = _caraMasakController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

    RecipeModel newRecipe = RecipeModel(
      id: '',
      title: _namaResepController.text.trim(),
      description: _deskripsiController.text.trim(),
      ingredients: ingredientsList,
      steps: stepsList,
      imageUrl: imageUrl,
      ownerId: currentUser.uid,
      ownerName: currentUser.displayName ?? 'Pengguna Anonim',
      ownerPhotoUrl: currentUser.photoURL,
      createdAt: Timestamp.now(),
      isPublic: _selectedPrivacy == PostPrivacy.publik,
    );

    try {
      await widget.recipeService.addRecipe(newRecipe);
      if (mounted) {
        // Keluar dari halaman ini terlebih dahulu
        Navigator.of(context).pop();
        // Beri jeda singkat agar halaman sebelumnya (misal HomePage) sempat ter-build ulang
        // sebelum notifikasi ditampilkan di atasnya.
        Future.delayed(const Duration(milliseconds: 200), () {
          CustomOverlayNotification.show(context, 'Resep berhasil di posting');
        });
      }
    } catch (e) {
      if(mounted) CustomOverlayNotification.show(context, 'Gagal memposting resep: ${e.toString()}', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    CustomOverlayNotification.show(context, 'Fungsi pilih gambar belum diimplementasikan.', isSuccess: false);
  }

  @override
  Widget build(BuildContext context) {
    // Bungkus Scaffold dengan WillPopScope
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined, color: AppColors.primaryOrange, size: 30),
            onPressed: () async {
              // Panggil logika yang sama seperti tombol back fisik
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('Tambah Resep', style: TextStyle(color: AppColors.secondaryTeal, fontWeight: FontWeight.bold)),
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
                  decoration: const InputDecoration(hintText: 'Masukkan nama resep anda'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama resep tidak boleh kosong' : null,
                ),
                _buildLabel('Deskripsi Singkat (Opsional)'),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(hintText: 'Ceritakan sedikit tentang resepmu'),
                  maxLines: 2,
                ),
                _buildLabel('Foto Masakan'),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey.shade500),
                        const SizedBox(height: 8),
                        Text('Masukkan foto masakan anda', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
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
                          child: const Text('Posting Resep', style: TextStyle(color: AppColors.white)),
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
}
