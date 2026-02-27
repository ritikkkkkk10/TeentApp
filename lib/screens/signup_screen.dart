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

    final googleUser =
        await GoogleSignIn().signIn();

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
      appBar: AppBar(title: const Text("Create Account")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// EMAIL
            TextField(
              controller: emailController,
              decoration:
                  const InputDecoration(labelText: "Email"),
            ),

            /// PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Password"),
            ),

            /// CONFIRM PASSWORD
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                      labelText: "Confirm Password"),
            ),

            const SizedBox(height: 20),

            /// EMAIL SIGNUP
            ElevatedButton(
              onPressed: signUp,
              child: const Text("Create Account"),
            ),

            const SizedBox(height: 20),

            /// GOOGLE SIGNUP
            OutlinedButton(
              onPressed: googleSignup,
              child:
                  const Text("Signup with Google"),
            ),

            const SizedBox(height: 20),

            /// ALREADY HAVE ACCOUNT
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
                  "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}