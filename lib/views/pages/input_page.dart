import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

enum PostPrivacy { publik, pribadi }

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaResepController = TextEditingController();
  final TextEditingController _bahanMasakanController = TextEditingController();
  final TextEditingController _caraMasakController = TextEditingController();

  PostPrivacy _selectedPrivacy = PostPrivacy.publik;

  @override
  void dispose() {
    _namaResepController.dispose();
    _bahanMasakanController.dispose();
    _caraMasakController.dispose();
    super.dispose();
  }

  // Widget untuk membuat label field
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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

  // Styling InputDecoration pada TextFormField
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // Helper widget untuk membangun tombol pilihan privasi
  Widget _buildPrivacyButton(String text, PostPrivacy value) {
    bool isSelected = _selectedPrivacy == value;

    // Menggunakan warna dari AppColors untuk tombol aktif
    final Color activeColor =
        AppColors.primaryGreen; // atau AppColors.secondaryTeal jika preferensi
    final Color activeTextColor =
        AppColors.white; // atau AppColors.textPrimaryLight

    final Color inactiveColor = Colors.transparent;
    final Color inactiveTextColor =
        AppColors.textSecondaryDark; // atau Colors.black54

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // Ganti dengan ikon kustom Anda jika sudah dibuat
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
            color: AppColors.secondaryTeal, // Menggunakan warna dari AppColors
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white, // Menggunakan warna dari AppColors
        elevation: 1,
        centerTitle: true,
        // automaticallyImplyLeading: false, // Tambahkan ini jika Anda menggunakan widget leading kustom sepenuhnya
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Resep
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
              const SizedBox(height: 20),

              // Foto Masakan
              _buildLabel('Foto Masakan'),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fungsi pilih gambar belum diimplementasikan.',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade400,
                    ), // Bisa juga AppColors.greyMedium
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 50,
                        color:
                            Colors
                                .grey
                                .shade500, // Bisa juga AppColors.greyMedium
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan foto masakan anda',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ), // Bisa juga AppColors.textSecondaryDark
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bahan Masakan
              _buildLabel('Bahan Masakan'),
              TextFormField(
                controller: _bahanMasakanController,
                decoration: _inputDecoration('Masukkan bahan masakan anda'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bahan masakan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Cara Masak
              _buildLabel('Cara Masak'),
              TextFormField(
                controller: _caraMasakController,
                decoration: _inputDecoration('Masukkan cara masak'),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cara masak tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Atur Postingan
              _buildLabel('Atur postingan sebagai'),
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color:
                      AppColors
                          .privacySwitchBackground, // Menggunakan warna dari AppColors
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

              // Tombol Posting
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      String namaResep = _namaResepController.text;
                      String privasi =
                          _selectedPrivacy == PostPrivacy.publik
                              ? 'Publik'
                              : 'Pribadi';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Posting Resep: $namaResep ($privasi)'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors
                            .secondaryTeal, // Menggunakan warna dari AppColors
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
                    style: TextStyle(
                      color: AppColors.white,
                    ), // Menggunakan warna dari AppColors
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
