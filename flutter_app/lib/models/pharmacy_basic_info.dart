class PharmacyBasicInfo {
  final String pharmacyId;
  final String businessName;
  final String email;
  final String phoneNumber;

  PharmacyBasicInfo({
    required this.pharmacyId,
    required this.businessName,
    required this.email,
    required this.phoneNumber,
  });

  factory PharmacyBasicInfo.fromJson(Map<String, dynamic> json) {
    return PharmacyBasicInfo(
      pharmacyId: json['pharmacy_id'] as String,
      businessName: json['business_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pharmacy_id': pharmacyId,
      'business_name': businessName,
      'email': email,
      'phone_number': phoneNumber,
    };
  }
}
