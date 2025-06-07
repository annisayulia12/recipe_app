import 'dart:async'; // Untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart'; // Impor package
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/firestore_service.dart';
import 'package:recipein_app/views/pages/home.dart';
import 'package:recipein_app/views/pages/user_recipes_page.dart';
import 'package:recipein_app/views/pages/notification_page.dart';
import 'package:recipein_app/views/pages/profile_page.dart';
import 'package:recipein_app/views/pages/input_page.dart';
import 'package:recipein_app/views/pages/detail_card.dart'; // Impor DetailCard untuk navigasi

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
  StreamSubscription? _linkSubscription; // Untuk listener link

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(firestoreService: widget.firestoreService, authService: widget.authService),
      UserRecipesPage(firestoreService: widget.firestoreService, authService: widget.authService),
      NotificationPage(firestoreService: widget.firestoreService, authService: widget.authService),
      ProfilePage(authService: widget.authService, firestoreService: widget.firestoreService),
    ];

    // Inisialisasi listener untuk Dynamic Links
    _initDynamicLinks();
  }

  // --- LOGIKA PENANGANAN DYNAMIC LINK ---
  Future<void> _initDynamicLinks() async {
    // 1. Menangani link yang membuka aplikasi saat aplikasi dalam keadaan terminated
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // 2. Menangani link yang masuk saat aplikasi berjalan di background
    _linkSubscription = FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData? dynamicLink) async {
        if (dynamicLink != null) {
          _handleDeepLink(dynamicLink);
        }
      },
      onError: (error) async {
        print('onLink error');
        print(error.message);
      },
    );
  }

  void _handleDeepLink(PendingDynamicLinkData link) {
    final Uri deepLink = link.link;
    // Cek apakah path link sesuai dengan yang kita harapkan (misalnya /resep)
    if (deepLink.path == '/resep') {
      // Ambil ID resep dari query parameter
      final String? recipeId = deepLink.queryParameters['id'];
      if (recipeId != null && recipeId.isNotEmpty) {
        print('Deep Link received for recipe ID: $recipeId');
        // Navigasi ke halaman detail resep
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailCard(
              recipeId: recipeId,
              firestoreService: widget.firestoreService,
              authService: widget.authService,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Penting untuk membatalkan subscription saat widget dihapus
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- UI ---
  // (UI build method dan _buildNavItem tetap sama seperti sebelumnya)

  @override
  Widget build(BuildContext context) {
    // ... (Kode UI build Anda yang sudah ada dengan BottomAppBar dan FAB) ...
    // Tidak ada perubahan yang diperlukan pada UI di sini
    return Scaffold(
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
        child: Container(
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
