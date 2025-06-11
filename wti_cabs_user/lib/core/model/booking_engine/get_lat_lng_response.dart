// Model for the top-level JSON object
class GetLatLngResponse {
  final bool success;
  final LatLong latLong;
  final String city;
  final String state;
  final String country;

  GetLatLngResponse({
    required this.success,
    required this.latLong,
    required this.city,
    required this.state,
    required this.country,
  });

  factory GetLatLngResponse.fromJson(Map<String, dynamic> json) {
    return GetLatLngResponse(
      success: json['success'] as bool,
      latLong: LatLong.fromJson(json['latLong'] as Map<String, dynamic>),
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'latLong': latLong.toJson(),
      'city': city,
      'state': state,
      'country': country,
    };
  }
}

// Model for the nested latLong object
class LatLong {
  final double lat;
  final double lng;

  LatLong({
    required this.lat,
    required this.lng,
  });

  factory LatLong.fromJson(Map<String, dynamic> json) {
    return LatLong(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}