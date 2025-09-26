class ServiceHubResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final List<ServiceHubResult>? result;

  ServiceHubResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory ServiceHubResponse.fromJson(Map<String, dynamic> json) {
    return ServiceHubResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => ServiceHubResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'statusCode': statusCode,
      'result': result?.map((e) => e.toJson()).toList(),
    };
  }
}

class ServiceHubResult {
  final String? id;
  final String? address;
  final String? city;
  final String? country;
  final LatLng? latlng;
  final num? rate;

  ServiceHubResult({
    this.id,
    this.address,
    this.city,
    this.country,
    this.latlng,
    this.rate,
  });

  factory ServiceHubResult.fromJson(Map<String, dynamic> json) {
    return ServiceHubResult(
      id: json['_id'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      latlng: json['latlng'] != null
          ? LatLng.fromJson(json['latlng'] as Map<String, dynamic>)
          : null,
      rate: json['rate'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'address': address,
      'city': city,
      'country': country,
      'latlng': latlng?.toJson(),
      'rate': rate,
    };
  }
}

class LatLng {
  final double? lat;
  final double? lng;
  final String? id;

  LatLng({
    this.lat,
    this.lng,
    this.id,
  });

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      '_id': id,
    };
  }
}
