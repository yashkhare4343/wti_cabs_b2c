class SuggestionPlacesResponse {
  final String primaryText;
  final String secondaryText;
  final String placeId;
  final List<String> types;
  final List<Term> terms;
  final String city;
  final String state;
  final String country;
  final bool isAirport;
  final double? latitude;
  final double? longitude;
  final String placeName;

  SuggestionPlacesResponse({
    required this.primaryText,
    required this.secondaryText,
    required this.placeId,
    required this.types,
    required this.terms,
    required this.city,
    required this.state,
    required this.country,
    required this.isAirport,
    this.latitude,
    this.longitude,
    this.placeName = '',
  });

  factory SuggestionPlacesResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionPlacesResponse(
      primaryText: json['primary_text'] as String? ?? '',
      secondaryText: json['secondary_text'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      types: (json['types'] as List<dynamic>?)?.cast<String>() ?? [],
      terms: (json['terms'] as List<dynamic>?)
          ?.map((e) => Term.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      isAirport: json['isAirport'] as bool? ?? false,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      placeName: json['place_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_text': primaryText,
      'secondary_text': secondaryText,
      'place_id': placeId,
      'types': types,
      'terms': terms.map((e) => e.toJson()).toList(),
      'city': city,
      'state': state,
      'country': country,
      'isAirport': isAirport,
      'latitude': latitude,
      'longitude': longitude,
      'place_name': placeName,
    };
  }
}

class Term {
  final int offset;
  final String value;

  Term({
    required this.offset,
    required this.value,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      offset: json['offset'] as int? ?? 0,
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'value': value,
    };
  }
}