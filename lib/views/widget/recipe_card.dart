import 'package:flutter/material.dart';
import 'package:recipein_app/views/pages/detail_card.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar makanan
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/image2.png',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            // Info profil dan nama resep
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/profile1.png'),
                  radius: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chicken Teriyaki',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Bahan-bahan ',
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailCard(),
                                ),
                              );
                            },
                            child: Text(
                              'selengkapnya',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icon row
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20),
                    const SizedBox(width: 8),
                    Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 8),
                    Icon(Icons.bookmark_border, size: 20),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
