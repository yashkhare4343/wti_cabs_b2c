class GoogleLatLngResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final Result? result;

  GoogleLatLngResponse({this.success, this.message, this.statusCode, this.result});

  factory GoogleLatLngResponse.fromJson(Map<String, dynamic> json) => GoogleLatLngResponse(
    success: json['success'] as bool?,
    message: json['message'] as String?,
    statusCode: json['statusCode'] as int?,
    result: json['result'] != null ? Result.fromJson(json['result'] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'statusCode': statusCode,
    'result': result?.toJson(),
  };
}

class Result {
  final String? city;
  final String? address;
  final num? rate; // can be int or double
  final LatLng? latlng;

  Result({this.city, this.address, this.rate, this.latlng});

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    city: json['city'] as String?,
    address: json['address'] as String?,
    rate: json['rate'] as num?,
    latlng: json['latlng'] != null ? LatLng.fromJson(json['latlng'] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    'city': city,
    'address': address,
    'rate': rate,
    'latlng': latlng?.toJson(),
  };
}

class LatLng {
  final double? lat;
  final double? lng;

  LatLng({this.lat, this.lng});

  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
  };
}
