import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  /// ================= EMAIL SIGNUP =================
  Future<void> signUp() async {

  if (passwordController.text.trim() !=
      confirmPasswordController.text.trim()) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Passwords do not match"),
      ),
    );
    return;
  }

  try {

    UserCredential credential =
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    /// send verification email
    await credential.user!.sendEmailVerification();

    /// IMPORTANT ✅ logout user
    await FirebaseAuth.instance.signOut();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Verification email sent. Verify before login ✅",
        ),
      ),
    );

    /// go back to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );

  } on FirebaseAuthException catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? "Signup failed")),
    );
  }
}

  /// ================= GOOGLE SIGNUP =================
Future<void> googleSignup() async {

  final GoogleSignIn googleSignIn =
      GoogleSignIn();

  /// ✅ clear firebase login
  await FirebaseAuth.instance.signOut();

  /// ✅ clear previous google account
  await googleSignIn.signOut();

  /// show account chooser
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

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
        builder: (_) => const HomeScreen()),
    (_) => false,
  );
}

  /// ================= UI =================
  @override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: Colors.grey.shade200,

    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [

            /// TOP HEADER
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                      vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xff1E4FA3),
                borderRadius:
                    BorderRadius.only(
                  bottomLeft:
                      Radius.circular(30),
                  bottomRight:
                      Radius.circular(30),
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
                      fontWeight:
                          FontWeight.bold,
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

            /// SIGNUP CARD
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.all(20),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(20),
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

                /// TEMP CONTENT
                child: Column(
  crossAxisAlignment:
      CrossAxisAlignment.stretch,
  children: [

    const Center(
      child: Text(
        "Create Account",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    const SizedBox(height: 25),

    /// EMAIL
    TextField(
      controller: emailController,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.person_outline),
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

    /// PASSWORD
    TextField(
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.key_outlined),
        suffixIcon:
            const Icon(Icons.visibility_off),
        hintText: "Create a password",
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

    /// CONFIRM PASSWORD
    TextField(
      controller:
          confirmPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.email_outlined),
        hintText: "Confirm password",
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),

    const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: signUp, // ✅ existing backend
    style: ElevatedButton.styleFrom(
      backgroundColor:
          const Color(0xff1E4FA3),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    ),
    child: const Text(
      "Sign Up",
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
      padding:
          EdgeInsets.symmetric(horizontal: 10),
      child: Text("Or connect with"),
    ),

    Expanded(
      child: Divider(
        color: Colors.grey,
      ),
    ),
  ],
),

const SizedBox(height: 20),

/// GOOGLE SIGNUP
SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton.icon(
    onPressed:
        googleSignup, // ✅ existing logic
    icon: Image.asset(
      "assets/google.png",
      height: 22,
    ),
    label: const Text(
      "Google",
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      side:
          BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    ),
  ),
),

//////////////////////////
///
///const SizedBox(height: 25),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    const Text(
      "Already have an account?",
      style: TextStyle(
        color: Colors.black54,
      ),
    ),

    TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(),
          ),
        );
      },
      child: const Text(
        "Login",
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