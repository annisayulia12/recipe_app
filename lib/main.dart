import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <-- IMPORT PROVIDER
import 'package:recipein_app/providers/user_profile_provider.dart'; // <-- IMPORT PROVIDER KITA
import 'package:recipein_app/services/auth_service.dart';
import 'package:recipein_app/services/user_service.dart';
import 'package:recipein_app/services/recipe_service.dart';
import 'package:recipein_app/services/interaction_service.dart';
import 'package:recipein_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';

const String appId = String.fromEnvironment(
  '__APP_ID',
  defaultValue: 'default-recipein-app-id',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://vfqioeascrhyyjsbuwhs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmcWlvZWFzY3JoeXlqc2J1d2hzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0OTczOTMsImV4cCI6MjA2NTA3MzM5M30.HFyGzfWDNFcpzhCY1CB4rNfxTwMGyjABhSvdrhVp3BQ',
  );

  // Inisialisasi semua layanan
  final userService = UserService();
  final recipeService = RecipeService();
  final notificationService = NotificationService();
  final interactionService = InteractionService(
    notificationService: notificationService,
    recipeService: recipeService,
  );
  final authService = AuthService(userService: userService);

  // --- PERUBAHAN DI SINI ---
  runApp(
    // Bungkus seluruh aplikasi dengan Provider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        // Anda bisa menambahkan provider lain di sini jika perlu
      ],
      child: MyApp(
        authService: authService,
        userService: userService,
        recipeService: recipeService,
        interactionService: interactionService,
        notificationService: notificationService,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final UserService userService;
  final RecipeService recipeService;
  final InteractionService interactionService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.authService,
    required this.userService,
    required this.recipeService,
    required this.interactionService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeIn App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ... tema Anda tidak berubah
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF2A7C76), width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A7C76),
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2A7C76),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: AuthGate(
        authService: authService,
        userService: userService,
        recipeService: recipeService,
        interactionService: interactionService,
        notificationService: notificationService,
      ),
    );
  }
}
