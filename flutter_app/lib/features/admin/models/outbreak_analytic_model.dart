class OutbreakAnalytic {
  final String requestedDrug;
  final int requestFrequency;
  final double centroidLatitude;
  final double centroidLongitude;

  OutbreakAnalytic({
    required this.requestedDrug,
    required this.requestFrequency,
    required this.centroidLatitude,
    required this.centroidLongitude,
  });

  factory OutbreakAnalytic.fromJson(Map<String, dynamic> json) {
    return OutbreakAnalytic(
      requestedDrug: json['requested_drug'] as String,
      requestFrequency: json['request_frequency'] as int,
      centroidLatitude: (json['centroid_latitude'] as num).toDouble(),
      centroidLongitude: (json['centroid_longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requested_drug': requestedDrug,
      'request_frequency': requestFrequency,
      'centroid_latitude': centroidLatitude,
      'centroid_longitude': centroidLongitude,
    };
  }
}
