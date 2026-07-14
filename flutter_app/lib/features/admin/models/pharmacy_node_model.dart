class PharmacyNode {
  final String pharmacyId;
  final String businessName;
  final String licenseNumber;
  final String email;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String generalLocation;
  final String accountStatus;
  final DateTime createdAt;

  PharmacyNode({
    required this.pharmacyId,
    required this.businessName,
    required this.licenseNumber,
    required this.email,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.generalLocation,
    required this.accountStatus,
    required this.createdAt,
  });

  factory PharmacyNode.fromJson(Map<String, dynamic> json) {
    return PharmacyNode(
      pharmacyId: json['pharmacy_id'] as String,
      businessName: json['business_name'] as String,
      licenseNumber: json['license_number'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      generalLocation: json['general_location'] as String? ?? 'Unknown Location',
      accountStatus: json['account_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pharmacy_id': pharmacyId,
      'business_name': businessName,
      'license_number': licenseNumber,
      'email': email,
      'phone_number': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'general_location': generalLocation,
      'account_status': accountStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
