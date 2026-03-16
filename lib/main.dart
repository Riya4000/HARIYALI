// ============================================================================
// MAIN APP - Entry point
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

// Services
import 'services/auth_service.dart';
import 'services/sensor_service.dart';
import 'services/voice_service.dart';  // ⭐ MAKE SURE THIS IS HERE
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HariyaliApp());
}

class HariyaliApp extends StatelessWidget {
  const HariyaliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Service
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Sensor Service
        ChangeNotifierProvider(create: (_) => SensorService()),

        // ⭐ VOICE SERVICE - ADD THIS!
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],

      child: MaterialApp(
        title: 'HARIYALI',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF4CAF50),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          textTheme: GoogleFonts.poppinsTextTheme(),

          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4CAF50),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 2,
              ),
            ),
          ),
        ),

        home: const SplashScreen(),

        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}