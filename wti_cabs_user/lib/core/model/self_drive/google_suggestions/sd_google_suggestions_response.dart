class SdGoogleSuggestionsResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final List<PlaceResult>? result;

  SdGoogleSuggestionsResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SdGoogleSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return SdGoogleSuggestionsResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
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

class PlaceResult {
  final String? primaryText;
  final String? secondaryText;
  final String? placeId;
  final String? city;
  final String? state;
  final String? country;
  final bool? isAirport;

  PlaceResult({
    this.primaryText,
    this.secondaryText,
    this.placeId,
    this.city,
    this.state,
    this.country,
    this.isAirport,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      primaryText: json['primary_text'] as String?,
      secondaryText: json['secondary_text'] as String?,
      placeId: json['place_id'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      isAirport: json['isAirport'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_text': primaryText,
      'secondary_text': secondaryText,
      'place_id': placeId,
      'city': city,
      'state': state,
      'country': country,
      'isAirport': isAirport,
    };
  }
}
