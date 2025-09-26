class SelfDriveMostPopularLocationResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final LocationResult? result;

  SelfDriveMostPopularLocationResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SelfDriveMostPopularLocationResponse.fromJson(Map<String, dynamic> json) {
    return SelfDriveMostPopularLocationResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? LocationResult.fromJson(json['result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'statusCode': statusCode,
      'result': result?.toJson(),
    };
  }
}

class LocationResult {
  final bool? isActive;
  final String? city;
  final LocationData? data;

  LocationResult({this.isActive, this.city, this.data});

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      isActive: json['isActive'] as bool?,
      city: json['city'] as String?,
      data: json['data'] != null ? LocationData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'city': city,
      'data': data?.toJson(),
    };
  }
}

class LocationData {
  final List<LocationItem>? residential;
  final List<LocationItem>? airport;
  final List<LocationItem>? hotel;

  LocationData({this.residential, this.airport, this.hotel});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      residential: (json['residential'] as List?)
          ?.map((e) => LocationItem.fromJson(e))
          .toList(),
      airport: (json['airport'] as List?)
          ?.map((e) => LocationItem.fromJson(e))
          .toList(),
      hotel: (json['hotel'] as List?)
          ?.map((e) => LocationItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'residential': residential?.map((e) => e.toJson()).toList(),
      'airport': airport?.map((e) => e.toJson()).toList(),
      'hotel': hotel?.map((e) => e.toJson()).toList(),
    };
  }
}

class LocationItem {
  final String? id;
  final String? countryCode;
  final String? city;
  final String? type;
  final String? address;
  final num? rate;
  final LatLngData? latlng;

  LocationItem({
    this.id,
    this.countryCode,
    this.city,
    this.type,
    this.address,
    this.rate,
    this.latlng,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['_id'] as String?,
      countryCode: json['countryCode'] as String?,
      city: json['city'] as String?,
      type: json['type'] as String?,
      address: json['address'] as String?,
      rate: json['rate'] as num?,
      latlng: json['latlng'] != null ? LatLngData.fromJson(json['latlng']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'countryCode': countryCode,
      'city': city,
      'type': type,
      'address': address,
      'rate': rate,
      'latlng': latlng?.toJson(),
    };
  }
}

class LatLngData {
  final num? lat;
  final num? lng;
  final String? id;

  LatLngData({this.lat, this.lng, this.id});

  factory LatLngData.fromJson(Map<String, dynamic> json) {
    return LatLngData(
      lat: json['lat'] as num?,
      lng: json['lng'] as num?,
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
