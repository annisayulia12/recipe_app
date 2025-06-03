// lib/views/widget/button_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/views/pages/home.dart';
import 'package:recipein_app/views/pages/user_recipes_page.dart'; // Halaman baru
import 'package:recipein_app/views/pages/notification_page.dart';
import 'package:recipein_app/views/pages/profile_page.dart';
import 'package:recipein_app/views/pages/input_page.dart';

class ButtonNavBar extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;

  const ButtonNavBar({
    super.key,
    required this.authService,
    required this.firestoreService,
  });

  @override
  State<ButtonNavBar> createState() => _ButtonNavBarState();
}

class _ButtonNavBarState extends State<ButtonNavBar> {
  int _selectedIndex = 0; // Default ke Beranda
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        firestoreService: widget.firestoreService,
        authService: widget.authService,
      ),
      UserRecipesPage( // Halaman baru untuk resep pengguna
        firestoreService: widget.firestoreService,
        authService: widget.authService,
      ),
      NotificationPage(
        firestoreService: widget.firestoreService,
        authService: widget.authService,
      ),
      ProfilePage(
        authService: widget.authService,
        firestoreService: widget.firestoreService,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton( // FAB selalu ada, tapi fungsinya bisa beda
              onPressed: () {
                // Navigasi ke InputPage untuk menambah resep baru
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InputPage(
                      firestoreService: widget.firestoreService,
                      authService: widget.authService,
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primaryGreen,
              shape: const CircleBorder(),
              elevation: 6,
              child: const Icon(Icons.add, color: AppColors.white, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Posisi di tengah
      bottomNavigationBar: BottomAppBar( // Gunakan BottomAppBar untuk docking FAB
        shape: const CircularNotchedRectangle(), // Bentuk notch untuk FAB
        notchMargin: 6.0, // Jarak antara FAB dan BottomAppBar
        color: AppColors.white,
        elevation: 8.0, // Beri shadow
        child: Container(
          height: 60.0, // Tinggi BottomAppBar
          decoration: const BoxDecoration(
             borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
             ),
             // Tidak perlu boxShadow di sini jika sudah di BottomAppBar elevation
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(Icons.home_outlined, Icons.home, 'Beranda', 0),
              _buildNavItem(Icons.menu_book_outlined, Icons.menu_book, 'Resep Saya', 1), // Item baru
              const SizedBox(width: 40), // Spacer untuk FAB
              _buildNavItem(Icons.notifications_outlined, Icons.notifications, 'Notifikasi', 2),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded( // Agar setiap item memiliki lebar yang sama
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          customBorder: const CircleBorder(), // Efek ripple bulat
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primaryOrange : AppColors.greyDark,
                  size: 24, // Ukuran ikon
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryOrange : AppColors.greyDark,
                    fontSize: 10, // Ukuran font label
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
