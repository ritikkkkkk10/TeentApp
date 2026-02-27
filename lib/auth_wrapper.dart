import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        /// loading state
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        /// user logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        /// user not logged in
        return const LoginScreen();
      },
    );
  }
}