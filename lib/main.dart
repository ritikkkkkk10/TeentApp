import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tent_app/auth_wrapper.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'auth_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      locale: const Locale('hi'),   // 👈 ADD HERE

  supportedLocales: const [
    Locale('en'),
    Locale('hi'),
  ],

  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        primaryColor: const Color(0xFF1E4FA3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E4FA3),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
