import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/features/bookings/models/business_profile_model.dart';

class BusinessProfileService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> saveProfile({
    required String businessId,
    required BusinessProfile profile,
  }) async {
    await firestore
        .collection("businesses")
        .doc(businessId)
        .collection("meta")
        .doc("profile")
        .set(profile.toMap());
  }

  Future<BusinessProfile?> getProfile(String businessId) async {
    final doc = await firestore
        .collection("businesses")
        .doc(businessId)
        .collection("meta")
        .doc("profile")
        .get();

    if (!doc.exists) return null;

    return BusinessProfile.fromMap(doc.data()!);
  }
}