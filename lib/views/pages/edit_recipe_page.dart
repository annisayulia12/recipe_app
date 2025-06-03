import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';

enum PostPrivacy { publik, pribadi }

class EditRecipePage extends StatefulWidget {
  final Map<String, dynamic>? recipeData;

  const EditRecipePage({super.key, this.recipeData});

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaResepController = TextEditingController();
  final TextEditingController _bahanMasakanController = TextEditingController();
  final TextEditingController _caraMasakController = TextEditingController();

  PostPrivacy _selectedPrivacy = PostPrivacy.publik;
  String? _recipeImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.recipeData != null) {
      _namaResepController.text = widget.recipeData!['recipeName'] ?? '';
      if (widget.recipeData!['ingredients'] is List) {
        _bahanMasakanController
            .text = (widget.recipeData!['ingredients'] as List).join('\n');
      } else {
        _bahanMasakanController.text = widget.recipeData!['ingredients'] ?? '';
      }

      if (widget.recipeData!['steps'] is List) {
        _caraMasakController.text = (widget.recipeData!['steps'] as List).join(
          '\n',
        );
      } else {
        _caraMasakController.text = widget.recipeData!['steps'] ?? '';
      }

      // Set privasi
      final String privacyString = widget.recipeData!['privacy'] ?? 'publik';
      _selectedPrivacy =
          privacyString.toLowerCase() == 'pribadi'
              ? PostPrivacy.pribadi
              : PostPrivacy.publik;

      // Set gambar resep
      _recipeImagePath = widget.recipeData!['recipeImageUrl'];
    }
  }

  @override
  void dispose() {
    _namaResepController.dispose();
    _bahanMasakanController.dispose();
    _caraMasakController.dispose();
    super.dispose();
  }

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
          'Edit Resep',
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
                        'Fungsi pilih/ubah gambar belum diimplementasikan.',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _recipeImagePath != null && _recipeImagePath!.isNotEmpty
                          ? Image.asset(
                            _recipeImagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                          : Column(
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

              // Tombol Update Resep
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      String namaResep = _namaResepController.text;
                      String bahanMasakan = _bahanMasakanController.text;
                      String caraMasak = _caraMasakController.text;
                      String privasi =
                          _selectedPrivacy == PostPrivacy.publik
                              ? 'Publik'
                              : 'Pribadi';
                      //print
                      ('Update Resep:');
                      //print
                      ('Nama Resep: $namaResep');
                      //print
                      ('Bahan Masakan: $bahanMasakan');
                      //print
                      ('Cara Masak: $caraMasak');
                      //print
                      ('Privasi: $privasi');
                      //print
                      ('Gambar Resep: $_recipeImagePath');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Resep "$namaResep" berhasil diperbarui!',
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
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
                    'Update Resep',
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
