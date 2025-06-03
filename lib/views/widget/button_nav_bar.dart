import 'package:flutter/material.dart';
import 'package:recipein_app/constants/app_colors.dart';
import 'package:recipein_app/views/pages/home.dart';
import 'package:recipein_app/views/pages/notification_page.dart';
import 'package:recipein_app/views/pages/profile_page.dart';
import 'package:recipein_app/views/pages/input_page.dart';

class ButtonNavBar extends StatefulWidget {
  const ButtonNavBar({super.key});

  @override
  State<ButtonNavBar> createState() => _ButtonNavBarState();
}

class _ButtonNavBarState extends State<ButtonNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    NotificationPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InputPage()),
                  );
                },
                backgroundColor: AppColors.primaryGreen,
                shape: const CircleBorder(),
                elevation: 6,
                child: const Icon(Icons.add, color: AppColors.white),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyMedium.withAlpha((255 * 0.2).round()),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home, color: AppColors.primaryOrange),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(
                  Icons.notifications,
                  color: AppColors.primaryOrange,
                ),
                label: 'Notifikasi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person, color: AppColors.primaryOrange),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            iconSize: 28.0,
            selectedItemColor: AppColors.primaryOrange,
            unselectedItemColor: AppColors.greyMedium,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      extendBody: true,
    );
  }
}
