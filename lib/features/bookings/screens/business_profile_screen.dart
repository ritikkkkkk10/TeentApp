import 'package:flutter/material.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'package:tent_app/features/bookings/models/business_profile_model.dart';
import 'package:tent_app/features/inventory/services/business_profile_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    if (businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.businessProfile)),
      body: Container(
        color: Colors.grey.shade200,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              buildField(
                icon: Icons.business,
                hint: AppLocalizations.of(context)!.businessName,
                controller: businessNameController,
              ),
              const SizedBox(height: 14),
              buildField(
                icon: Icons.person,
                hint: AppLocalizations.of(context)!.ownerName,
                controller: ownerNameController,
              ),
              const SizedBox(height: 14),
              buildField(
                icon: Icons.phone,
                hint: AppLocalizations.of(context)!.phone,
                controller: phoneController,
              ),
              const SizedBox(height: 14),
              buildField(
                icon: Icons.location_on,
                hint: AppLocalizations.of(context)!.businessAddress,
                controller: addressController,
              ),
              const SizedBox(height: 14),
              buildField(
                icon: Icons.receipt_long,
                hint: AppLocalizations.of(context)!.gst,
                controller: gstController,
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4FA3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.saveProfile,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF1E4FA3)),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
