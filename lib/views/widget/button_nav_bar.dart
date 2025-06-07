import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Impor untuk SystemNavigator
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/views/pages/home.dart';
import 'package:recipein_app/views/pages/user_recipes_page.dart';
import 'package:recipein_app/views/pages/notification_page.dart';
import 'package:recipein_app/views/pages/profile_page.dart';
import 'package:recipein_app/views/pages/input_page.dart';
import 'package:recipein_app/views/pages/detail_card.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart'; // Impor dialog baru

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
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(firestoreService: widget.firestoreService, authService: widget.authService),
      UserRecipesPage(firestoreService: widget.firestoreService, authService: widget.authService),
      NotificationPage(firestoreService: widget.firestoreService, authService: widget.authService),
      ProfilePage(authService: widget.authService, firestoreService: widget.firestoreService),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initDynamicLinks();
      }
    });
  }
  
  Future<void> _initDynamicLinks() async {
    // ... (kode ini tetap sama)
  }

  void _handleDeepLink(PendingDynamicLinkData link) {
    // ... (kode ini tetap sama)
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Fitur 3: Dialog Konfirmasi Keluar Aplikasi ---
  Future<bool> _onWillPop() async {
    // Hanya tampilkan dialog jika pengguna berada di tab Beranda (index 0)
    if (_selectedIndex != 0) {
      // Jika tidak di Beranda, navigasi kembali ke Beranda
      setState(() {
        _selectedIndex = 0;
      });
      // Kembalikan false agar aplikasi tidak keluar
      return false;
    }

    // Jika sudah di Beranda, tampilkan dialog konfirmasi
    final bool? shouldPop = await showCustomConfirmationDialog(
      context: context,
      title: 'Keluar dari aplikasi?',
      content: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: <InlineSpan>[
            const TextSpan(text: 'Apakah anda yakin akan keluar dari aplikasi '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image.asset('assets/images/logo.png', height: 16), // Tampilkan logo
            ),
            const TextSpan(text: '?'),
          ],
        ),
      ),
      confirmText: 'Keluar',
      cancelText: 'Batal',
    );
    
    // Jika pengguna menekan "Keluar", tutup aplikasi.
    if (shouldPop == true) {
      SystemNavigator.pop();
    }
    
    // Kembalikan false agar Flutter tidak menangani tombol back lagi
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          color: AppColors.white,
          elevation: 8.0,
          child: SizedBox(
            height: 60.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(Icons.home_outlined, Icons.home, 'Beranda', 0),
                _buildNavItem(Icons.menu_book_outlined, Icons.menu_book, 'Resep Saya', 1),
                const SizedBox(width: 40),
                _buildNavItem(Icons.notifications_outlined, Icons.notifications, 'Notifikasi', 2),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primaryOrange : AppColors.greyDark,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryOrange : AppColors.greyDark,
                    fontSize: 10,
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
