class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
  final String address;
  final String? gst;

  BusinessProfile({
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.address,
    this.gst,
  });

  Map<String, dynamic> toMap() {
    return {
      "businessName": businessName,
      "ownerName": ownerName,
      "phone": phone,
      "address": address,
      "gst": gst,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      businessName: map["businessName"] ?? "",
      ownerName: map["ownerName"] ?? "",
      phone: map["phone"] ?? "",
      address: map["address"] ?? "",
      gst: map["gst"],
    );
  }
}