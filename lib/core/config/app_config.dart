import 'package:firebase_auth/firebase_auth.dart';
import 'package:tent_app/core/config/app_config.dart';

/// ===============================
/// APP RUNNING MODE
/// ===============================
enum AppMode {
  demoSingleBusiness,
  multiBusiness,
}

/// CHANGE THIS LATER ONLY
const AppMode appMode = AppMode.multiBusiness;

/// ===============================
/// BUSINESS ID PROVIDER
/// ===============================
Future<String> getBusinessId() async {

  if (appMode == AppMode.demoSingleBusiness) {
    return "test_business_5";
  }

  User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    user = await FirebaseAuth.instance.authStateChanges().first;
  }

  return user!.uid;
}