import 'package:firebase_auth/firebase_auth.dart';

/// ===============================
/// APP RUNNING MODE
/// ===============================
enum AppMode {
  demoSingleBusiness,
  multiBusiness,
}

/// CHANGE THIS LATER ONLY
const AppMode appMode = AppMode.demoSingleBusiness;

/// ===============================
/// BUSINESS ID PROVIDER
/// ===============================
Future<String> getBusinessId() async {

  /// DEVELOPMENT MODE
  if (appMode == AppMode.demoSingleBusiness) {
    return "demo_business";
  }

  /// FUTURE REAL SAAS MODE
  final user = FirebaseAuth.instance.currentUser!;

  // Later we will fetch businessId from Firestore users collection
  return user.uid;
}