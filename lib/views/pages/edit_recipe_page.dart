import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';
import 'package:recipein_app/widgets/custom_overlay_notification.dart';

// Pastikan enum ini ada jika belum dipindahkan ke file terpisah
enum PostPrivacy { publik, pribadi }

class EditRecipePage extends StatefulWidget {
  final RecipeModel initialRecipe;
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
  bool _isFormDirty = false; // State untuk melacak perubahan

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data resep yang ada
    _namaResepController = TextEditingController(text: widget.initialRecipe.title);
    _deskripsiController = TextEditingController(text: widget.initialRecipe.description ?? '');
    _bahanMasakanController = TextEditingController(text: widget.initialRecipe.ingredients.join('\n'));
    _caraMasakController = TextEditingController(text: widget.initialRecipe.steps.join('\n'));
    _selectedPrivacy = widget.initialRecipe.isPublic ? PostPrivacy.publik : PostPrivacy.pribadi;

    // Tambahkan listener untuk mendeteksi perubahan
    _namaResepController.addListener(_setFormDirty);
    _deskripsiController.addListener(_setFormDirty);
    _bahanMasakanController.addListener(_setFormDirty);
    _caraMasakController.addListener(_setFormDirty);
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

  // --- Fitur 2: Dialog Konfirmasi Keluar ---
  Future<bool> _onWillPop() async {
    if (!_isFormDirty) {
      return true; // Izinkan keluar jika tidak ada perubahan
    }
    final bool? shouldPop = await showCustomConfirmationDialog(
      context: context,
      title: 'Keluar dari halaman?',
      content: const Text('Perubahan yang Anda lakukan mungkin belum disimpan.', textAlign: TextAlign.center),
      confirmText: 'Keluar',
      cancelText: 'Batal',
    );
    return shouldPop ?? false; // Jika dialog ditutup, anggap batal
  }

  // --- Fitur 1: Notifikasi Kustom untuk Update ---
  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? imageUrl = widget.initialRecipe.imageUrl; // Placeholder
    List<String> ingredientsList = _bahanMasakanController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    List<String> stepsList = _caraMasakController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

    RecipeModel updatedRecipe = widget.initialRecipe.copyWith(
      title: _namaResepController.text.trim(),
      description: _deskripsiController.text.trim(),
      ingredients: ingredientsList,
      steps: stepsList,
      imageUrl: imageUrl,
      isPublic: _selectedPrivacy == PostPrivacy.publik,
      updatedAt: Timestamp.now(),
    );

    try {
      await widget.firestoreService.updateRecipe(updatedRecipe);
      if (mounted) {
        // Kirim 'true' kembali untuk menandakan ada perubahan
        Navigator.of(context).pop(true);
        // Beri jeda agar notifikasi muncul di halaman sebelumnya
        Future.delayed(const Duration(milliseconds: 200), () {
          CustomOverlayNotification.show(context, 'Resep berhasil diperbarui');
        });
      }
    } catch (e) {
      if (mounted) CustomOverlayNotification.show(context, 'Gagal memperbarui resep', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          title: const Text('Edit Resep', style: TextStyle(color: AppColors.secondaryTeal, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.white, elevation: 1, centerTitle: true,
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
                Container(
                  height: 150, width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text("UI untuk edit gambar akan datang")),
                ),

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
                  decoration: BoxDecoration(color: AppColors.privacySwitchBackground, borderRadius: BorderRadius.circular(10.0)),
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
                          onPressed: _updateRecipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryTeal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Simpan Perubahan', style: TextStyle(color: AppColors.white)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget helper ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildPrivacyButton(String text, PostPrivacy value) {
    bool isSelected = _selectedPrivacy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _setFormDirty();
          setState(() => _selectedPrivacy = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: isSelected ? AppColors.white : AppColors.textSecondaryDark, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
