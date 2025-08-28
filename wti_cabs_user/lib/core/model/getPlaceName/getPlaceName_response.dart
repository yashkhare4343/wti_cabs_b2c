class GetPlaceNameResponse {
  final bool? success;
  final String? lat;
  final String? lng;
  final String? nearestAddress;

  GetPlaceNameResponse({
    this.success,
    this.lat,
    this.lng,
    this.nearestAddress,
  });

  factory GetPlaceNameResponse.fromJson(Map<String, dynamic> json) {
    return GetPlaceNameResponse(
      success: json['success'] as bool?,
      lat: json['lat'] as String?,
      lng: json['lng'] as String?,
      nearestAddress: json['nearestAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'lat': lat,
      'lng': lng,
      'nearestAddress': nearestAddress,
    };
  }
}
