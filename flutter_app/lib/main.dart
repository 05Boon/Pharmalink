import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
    url: 'https://fjnbnbtjsuxumtmhcidh.supabase.co',
    publishableKey: ' sb_publishable_t2XYPBX8gmvQpyXjXDaBUg_X6WdliU_',  );
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
