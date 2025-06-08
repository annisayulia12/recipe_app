import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/notification_service.dart';
import 'package:recipein_app/views/pages/home.dart';
import 'package:recipein_app/views/pages/user_recipes_page.dart';
import 'package:recipein_app/views/pages/notification_page.dart';
import 'package:recipein_app/views/pages/profile_page.dart';
import 'package:recipein_app/views/pages/input_page.dart';
import 'package:recipein_app/views/pages/detail_card.dart';
import 'package:recipein_app/widgets/custom_confirmation_dialog.dart';

class ButtonNavBar extends StatefulWidget {
  final AuthService authService;
  final UserService userService;
  final RecipeService recipeService;
  final InteractionService interactionService;
  final NotificationService notificationService;

  const ButtonNavBar({
    super.key,
    required this.authService,
    required this.userService,
    required this.recipeService,
    required this.interactionService,
    required this.notificationService,
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
      HomePage(
        recipeService: widget.recipeService,
        authService: widget.authService,
        interactionService: widget.interactionService,
      ),
      UserRecipesPage(
        recipeService: widget.recipeService,
        authService: widget.authService,
        interactionService: widget.interactionService,
      ),
      // *** PERBAIKAN DI SINI: Teruskan semua layanan yang dibutuhkan oleh NotificationPage ***
      NotificationPage(
        notificationService: widget.notificationService,
        authService: widget.authService,
        recipeService: widget.recipeService,
        interactionService: widget.interactionService,
      ),
      ProfilePage(
        authService: widget.authService,
        userService: widget.userService,
      ),
    ];
    
    // Panggil initDynamicLinks setelah frame pertama selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initDynamicLinks();
      }
    });
  }

  Future<void> _initDynamicLinks() async {
    _linkSubscription = FirebaseDynamicLinks.instance.onLink.listen(
      (dynamicLink) {
        if (dynamicLink != null) {
          _handleDeepLink(dynamicLink);
        }
      },
      onError: (e) async => print('onLink error: ${e.message}'),
    );

    final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }
  }

  void _handleDeepLink(PendingDynamicLinkData link) {
    final Uri deepLink = link.link;
    if (deepLink.path == '/resep') {
      final String? recipeId = deepLink.queryParameters['id'];
      if (recipeId != null && recipeId.isNotEmpty) {
        // Gunakan context yang valid untuk navigasi
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailCard(
              recipeId: recipeId,
              recipeService: widget.recipeService,
              interactionService: widget.interactionService,
              authService: widget.authService,
            ),
          ),
        );
      }
    }
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

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    
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
              child: Image.asset('assets/images/logo.png', height: 16),
            ),
            const TextSpan(text: '?'),
          ],
        ),
      ),
      confirmText: 'Keluar',
      cancelText: 'Batal',
    );
    
    if (shouldPop == true) {
      SystemNavigator.pop();
    }
    
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
                  recipeService: widget.recipeService,
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
