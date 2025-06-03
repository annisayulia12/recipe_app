import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart'; // Impor file warna Anda

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "Vanyara";
  final TextEditingController _nameController = TextEditingController();

  void _editUserName() {
    _nameController.text = userName;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Nama"),
            content: TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "Masukkan nama baru"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    userName = _nameController.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F2F1), AppColors.primaryGreen],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/profile5.png'),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Nama pengguna + edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _editUserName,
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'vanyara@gmail.com',
                  style: TextStyle(color: AppColors.textPrimaryLight),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildListTile(
                  icon: Icons.lock,
                  title: 'Ganti Kata Sandi',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Keluar',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.greyMedium,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
