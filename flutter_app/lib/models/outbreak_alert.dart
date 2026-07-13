class OutbreakAlert {
  final String location;
  final String drugCategory;
  final String shortageReason;
  final int incidentCount;

  OutbreakAlert({
    required this.location,
    required this.drugCategory,
    required this.shortageReason,
    required this.incidentCount,
  });

  factory OutbreakAlert.fromJson(Map<String, dynamic> json) {
    return OutbreakAlert(
      location: json['location'] as String,
      drugCategory: json['drug_category'] as String,
      shortageReason: json['shortage_reason'] as String,
      incidentCount: json['incident_count'] as int,
    );
  }
}
