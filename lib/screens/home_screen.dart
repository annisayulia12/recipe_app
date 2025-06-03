// import 'package:flutter/material.dart';
// import 'package:recipein_app/views/widget/recipe_card.dart';
// import '../widgets/recipe_card.dart';
// import '../widgets/bottom_navbar.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Text(
//                 "Explore your recipe",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: ListView(
//                 children: const [
//                   RecipeCard(
//                     title: 'Chicken Teriyaki',
//                     imagePath: 'assets/images/chicken_teriyaki.jpg',
//                   ),
//                   RecipeCard(
//                     title: 'Chicken Teriyaki',
//                     imagePath: 'assets/images/chicken_teriyaki.jpg',
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: const BottomNavbar(),
//     );
//   }
// }
