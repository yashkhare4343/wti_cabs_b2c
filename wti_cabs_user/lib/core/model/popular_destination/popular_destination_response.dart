class PopularResponse {
  final bool success;
  final String? message;
  final List<RecentReservation>? recentReservations;
  final List<PopularCity>? popularCities;
  final List<PopularAirport>? popularAirports;

  PopularResponse({
    required this.success,
    this.message,
    this.recentReservations,
    this.popularCities,
    this.popularAirports,
  });

  factory PopularResponse.fromJson(Map<String, dynamic> json) {
    return PopularResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      recentReservations: (json['recentReservations'] as List<dynamic>?)
          ?.map((e) => RecentReservation.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularCities: (json['popularCities'] as List<dynamic>?)
          ?.map((e) => PopularCity.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularAirports: (json['popularAirports'] as List<dynamic>?)
          ?.map((e) => PopularAirport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecentReservation {
  final Source? source;
  final Destination? destination;
  final String? pickupDateAndTime;
  final String? returnDateAndTime;
  final List<dynamic>? stopsArray;
  final PackageSelected? packageSelected;
  final int? tripCode;

  RecentReservation({
    this.source,
    this.destination,
    this.pickupDateAndTime,
    this.returnDateAndTime,
    this.stopsArray,
    this.packageSelected,
    this.tripCode,
  });

  factory RecentReservation.fromJson(Map<String, dynamic> json) {
    return RecentReservation(
      source: json['source'] != null ? Source.fromJson(json['source'] as Map<String, dynamic>) : null,
      destination: json['destination'] != null ? Destination.fromJson(json['destination'] as Map<String, dynamic>) : null,
      pickupDateAndTime: json['pickupDateAndTime'] as String?,
      returnDateAndTime: json['returnDateAndTime'] as String?,
      stopsArray: json['stopsArray'] as List<dynamic>?,
      packageSelected: json['packageSelected'] != null
          ? PackageSelected.fromJson(json['packageSelected'] as Map<String, dynamic>)
          : null,
      tripCode: json['tripCode'] as int?,
    );
  }
}

class Source {
  final String? sourcePlaceId;
  final String? sourceTitle;
  final String? sourceState;
  final String? sourceCity;
  final String? sourceCountry;
  final List<String>? sourceType;
  final double? latitude;
  final double? longitude;

  Source({
    this.sourcePlaceId,
    this.sourceTitle,
    this.sourceState,
    this.sourceCity,
    this.sourceCountry,
    this.sourceType,
    this.latitude,
    this.longitude,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      sourcePlaceId: json['sourcePlaceId'] as String?,
      sourceTitle: json['sourceTitle'] as String?,
      sourceState: json['sourceState'] as String?,
      sourceCity: json['sourceCity'] as String?,
      sourceCountry: json['sourceCountry'] as String?,
      sourceType: (json['sourceType'] as List<dynamic>?)?.cast<String>(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class Destination {
  final String? destinationPlaceId;
  final String? destinationTitle;
  final String? destinationState;
  final String? destinationCity;
  final String? destinationCountry;
  final List<String>? destinationType;
  final double? latitude;
  final double? longitude;

  Destination({
    this.destinationPlaceId,
    this.destinationTitle,
    this.destinationState,
    this.destinationCity,
    this.destinationCountry,
    this.destinationType,
    this.latitude,
    this.longitude,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      destinationPlaceId: json['destinationPlaceId'] as String?,
      destinationTitle: json['destinationTitle'] as String?,
      destinationState: json['destinationState'] as String?,
      destinationCity: json['destinationCity'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      destinationType: (json['destinationType'] as List<dynamic>?)?.cast<String>(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class PackageSelected {
  final String? km;
  final String? hours;

  PackageSelected({
    this.km,
    this.hours,
  });

  factory PackageSelected.fromJson(Map<String, dynamic> json) {
    return PackageSelected(
      km: json['km'] as String?,
      hours: json['hours'] as String?,
    );
  }
}

class PopularCity {
  final String? id;
  final String? imageUrl;
  final String? placeId;
  final int? v;
  final bool? isActive;
  final String? city;
  final String? country;
  final String? state;
  final double? lat;
  final double? long;
  final List<String>? types;
  final List<Term>? terms;
  final String? secondaryText;
  final String? primaryText;
  final bool? isAirport;
  final String? airportCode;

  PopularCity({
    this.id,
    this.imageUrl,
    this.placeId,
    this.v,
    this.isActive,
    this.city,
    this.country,
    this.state,
    this.lat,
    this.long,
    this.types,
    this.terms,
    this.secondaryText,
    this.primaryText,
    this.isAirport,
    this.airportCode,
  });

  factory PopularCity.fromJson(Map<String, dynamic> json) {
    return PopularCity(
      id: json['_id'] as String?,
      imageUrl: json['imageUrl'] as String?,
      placeId: json['place_id'] as String?,
      v: json['__v'] as int?,
      isActive: json['isActive'] as bool?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
      types: (json['types'] as List<dynamic>?)?.cast<String>(),
      terms: (json['terms'] as List<dynamic>?)?.map((e) => Term.fromJson(e as Map<String, dynamic>)).toList(),
      secondaryText: json['secondary_text'] as String?,
      primaryText: json['primary_text'] as String?,
      isAirport: json['isAirport'] as bool?,
      airportCode: json['airportCode'] as String?,
    );
  }
}

class PopularAirport {
  final String? id;
  final String? country;
  final String? state;
  final String? city;
  final String? primaryText;
  final String? secondaryText;
  final String? imageUrl;
  final String? placeId;
  final bool? isActive;
  final double? lat;
  final double? long;
  final bool? isAirport;
  final int? v;
  final List<Term>? terms;
  final List<String>? types;
  final String? airportCode;

  PopularAirport({
    this.id,
    this.country,
    this.state,
    this.city,
    this.primaryText,
    this.secondaryText,
    this.imageUrl,
    this.placeId,
    this.isActive,
    this.lat,
    this.long,
    this.isAirport,
    this.v,
    this.terms,
    this.types,
    this.airportCode,
  });

  factory PopularAirport.fromJson(Map<String, dynamic> json) {
    return PopularAirport(
      id: json['_id'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      primaryText: json['primary_text'] as String?,
      secondaryText: json['secondary_text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      placeId: json['place_id'] as String?,
      isActive: json['isActive'] as bool?,
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
      isAirport: json['isAirport'] as bool?,
      v: json['__v'] as int?,
      terms: (json['terms'] as List<dynamic>?)?.map((e) => Term.fromJson(e as Map<String, dynamic>)).toList(),
      types: (json['types'] as List<dynamic>?)?.cast<String>(),
      airportCode: json['airportCode'] as String?,
    );
  }
}

class Term {
  final int? offset;
  final String? value;

  Term({
    this.offset,
    this.value,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      offset: json['offset'] as int?,
      value: json['value'] as String?,
    );
  }
}