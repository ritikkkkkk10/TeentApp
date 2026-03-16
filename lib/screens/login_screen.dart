import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool canSendReset = true;
  int resetCooldown = 30;

  Future<void> login() async {

    UserCredential credential =
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    await credential.user!.reload();

    if (!credential.user!.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verify email first"),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => const HomeScreen()),
    );
  }

  /// GOOGLE LOGIN
  Future<void> googleLogin() async {

  final GoogleSignIn googleSignIn =
      GoogleSignIn();

  /// ✅ CLEAR FIREBASE SESSION
  await FirebaseAuth.instance.signOut();

  /// ✅ CLEAR GOOGLE SESSION
  await googleSignIn.signOut();

  /// NOW SHOW ACCOUNT PICKER
  final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

  if (googleUser == null) return;

  final googleAuth =
      await googleUser.authentication;

  final credential =
      GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  await FirebaseAuth.instance
      .signInWithCredential(credential);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
        builder: (_) => const HomeScreen()),
  );
}

Future<void> showResetPasswordDialog() async {

  final resetEmailController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (context) {

      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Reset Password"),

        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(
            hintText: "Enter your email",
          ),
        ),

        actions: [

          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          StatefulBuilder(
  builder: (context, setStateDialog) {

    return ElevatedButton(
      onPressed: canSendReset
          ? () async {

              final email =
                  resetEmailController.text.trim();

              if (email.isEmpty) return;

              await FirebaseAuth.instance
                  .sendPasswordResetEmail(
                      email: email);

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                      "Password reset link sent ✅"),
                ),
              );

              /// START COOLDOWN
              canSendReset = false;
resetCooldown = 30;

Future.doWhile(() async {

  await Future.delayed(
      const Duration(seconds: 1));

  resetCooldown--;

  setStateDialog(() {});

  if (resetCooldown <= 0) {
    canSendReset = true;
    setStateDialog(() {});
    return false;
  }

  return true;
});

            }
          : null,

      child: Text(
        canSendReset
            ? "Send"
            : "Wait ${resetCooldown}s",
      ),
    );
  },
),
        ],
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade200,

    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [

            /// TOP BLUE HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xff1E4FA3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.celebration,
                      color: Colors.white,
                      size: 60),

                  SizedBox(height: 10),

                  Text(
                    "Event Rental Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "App for Tent & Event Rental Businesses",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// LOGIN CARD
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black12,
                      blurRadius: 10,
                      offset:
                          Offset(0, 4),
                    )
                  ],
                ),

                /// KEEP OLD CONTENT HERE (NEXT STEP)
                child: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [

    const Center(
      child: Text(
        "Login",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    const SizedBox(height: 25),

    /// EMAIL FIELD
    TextField(
      controller: emailController,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.email_outlined),

        hintText: "Enter your email",

        filled: true,
        fillColor: Colors.grey.shade100,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),

    const SizedBox(height: 15),

    /// PASSWORD FIELD
    TextField(
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.lock_outline),

        suffixIcon:
            const Icon(Icons.visibility_off),

        hintText: "Enter your password",

        filled: true,
        fillColor: Colors.grey.shade100,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),

    const SizedBox(height: 10),

    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: showResetPasswordDialog,
        child:
            const Text("Forgot password?"),
      ),
    ),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: login, // ✅ BACKEND RECONNECTED
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff1E4FA3),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    ),
    child: const Text(
      "Login",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

const SizedBox(height: 20),

/// OR DIVIDER
Row(
  children: [
    Expanded(
      child: Divider(
        color: Colors.grey,
      ),
    ),

    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text("OR"),
    ),

    Expanded(
      child: Divider(
        color: Colors.grey,
      ),
    ),
  ],
),

const SizedBox(height: 20),

/// GOOGLE LOGIN
SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton.icon(
    onPressed: googleLogin,
    icon: Image.asset(
      "assets/google.png",
      height: 22,
    ),
    label: const Text(
      "Login with Google",
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 25),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    const Text(
      "Don't have an account?",
      style: TextStyle(color: Colors.black54),
    ),

    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SignupScreen(),
          ),
        );
      },
      child: const Text(
        "Create Account",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff1E4FA3),
        ),
      ),
    ),
  ],
),


  ],
),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}