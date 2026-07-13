import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_config.dart';
import 'routes/app_router.dart';

void main() async {
  // Required before any async work before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — must complete before app starts
  // anonKey is the public key safe to use in client apps
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl.isEmpty
        ? 'https://lqnmeegpjhzffjslxxek.supabase.co'
        : ApiConfig.supabaseUrl,
    publishableKey: ApiConfig.supabaseAnonKey.isEmpty
        ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxxbm1lZWdwamh6ZmZqc2x4eGVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NjAyNjAsImV4cCI6MjA5OTUzNjI2MH0.2-TwKQyVcu7lk3AymxsGXD2Tq1xH2tuAjnDLdAIxPfs'
        : ApiConfig.supabaseAnonKey,
  );

  runApp(const PharmacyNetworkApp());
}

class PharmacyNetworkApp extends StatelessWidget {
  const PharmacyNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pharmacy Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          primary: const Color(0xFF1D9E75),
          surface: const Color(0xFFF5F5F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F2),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}