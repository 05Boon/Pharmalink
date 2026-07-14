class OutbreakAnalytic {
  final String requestedDrug;
  final int requestFrequency;
  final double centroidLatitude;
  final double centroidLongitude;
  final String regionName;

  OutbreakAnalytic({
    required this.requestedDrug,
    required this.requestFrequency,
    required this.centroidLatitude,
    required this.centroidLongitude,
    required this.regionName,
  });

  factory OutbreakAnalytic.fromJson(Map<String, dynamic> json) {
    return OutbreakAnalytic(
      requestedDrug: json['requested_drug'] as String,
      requestFrequency: json['request_frequency'] as int,
      centroidLatitude: (json['centroid_latitude'] as num).toDouble(),
      centroidLongitude: (json['centroid_longitude'] as num).toDouble(),
      regionName: json['region_name'] as String? ?? 'Unknown Region',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requested_drug': requestedDrug,
      'request_frequency': requestFrequency,
      'centroid_latitude': centroidLatitude,
      'centroid_longitude': centroidLongitude,
      'region_name': regionName,
    };
  }
}
