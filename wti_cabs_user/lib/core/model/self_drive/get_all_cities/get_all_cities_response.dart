class GetAllCitiesResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final LocationsResult? result;

  GetAllCitiesResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory GetAllCitiesResponse.fromJson(Map<String, dynamic> json) {
    return GetAllCitiesResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? LocationsResult.fromJson(json['result'])
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

class LocationsResult {
  final bool? isActive;
  final String? tagline;
  final List<AvailableCountry>? availableInCountries;
  final List<LocationData>? data;

  LocationsResult({
    this.isActive,
    this.tagline,
    this.availableInCountries,
    this.data,
  });

  factory LocationsResult.fromJson(Map<String, dynamic> json) {
    return LocationsResult(
      isActive: json['isActive'] as bool?,
      tagline: json['tagline'] as String?,
      availableInCountries: (json['availableInCountries'] as List?)
          ?.map((e) => AvailableCountry.fromJson(e))
          .toList(),
      data: (json['data'] as List?)
          ?.map((e) => LocationData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'tagline': tagline,
      'availableInCountries':
      availableInCountries?.map((e) => e.toJson()).toList(),
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class AvailableCountry {
  final String? label;
  final String? value;

  AvailableCountry({this.label, this.value});

  factory AvailableCountry.fromJson(Map<String, dynamic> json) {
    return AvailableCountry(
      label: json['label'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

class LocationData {
  final String? id;
  final String? cityName;
  final String? slug;
  final String? image;
  final String? countryCode;

  LocationData({
    this.id,
    this.cityName,
    this.slug,
    this.image,
    this.countryCode,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      id: json['_id'] as String?,
      cityName: json['cityName'] as String?,
      slug: json['slug'] as String?,
      image: json['image'] as String?,
      countryCode: json['countryCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cityName': cityName,
      'slug': slug,
      'image': image,
      'countryCode': countryCode,
    };
  }
}
