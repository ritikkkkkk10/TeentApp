import 'package:flutter/material.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'package:tent_app/features/bookings/models/business_profile_model.dart';
import 'package:tent_app/features/inventory/services/business_profile_service.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final service = BusinessProfileService();

  final businessNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final gstController = TextEditingController();

  String? businessId;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    businessId = await getBusinessId();

    final profile = await service.getProfile(businessId!);

    if (profile != null) {
      businessNameController.text = profile.businessName;
      ownerNameController.text = profile.ownerName;
      phoneController.text = profile.phone;
      addressController.text = profile.address;
      gstController.text = profile.gst ?? "";
    }

    setState(() {});
  }

  Future<void> saveProfile() async {
    final profile = BusinessProfile(
      businessName: businessNameController.text,
      ownerName: ownerNameController.text,
      phone: phoneController.text,
      address: addressController.text,
      gst: gstController.text,
    );

    await service.saveProfile(
      businessId: businessId!,
      profile: profile,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profile Saved")));
  }

  @override
  Widget build(BuildContext context) {
    if (businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Business Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: businessNameController,
              decoration: const InputDecoration(labelText: "Business Name"),
            ),
            TextField(
              controller: ownerNameController,
              decoration: const InputDecoration(labelText: "Owner Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            TextField(
              controller: gstController,
              decoration: const InputDecoration(labelText: "GST (optional)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}