class GlobalResponse {
  final List<List<GlobalResult>> result;
  final TripTypeDetails? tripTypeDetails;

  GlobalResponse({
    required this.result,
    required this.tripTypeDetails,
  });

  factory GlobalResponse.fromJson(Map<String, dynamic> json) {
    return GlobalResponse(
      result: (json['result'] as List)
          .map((innerList) => (innerList as List)
          .map((item) => GlobalResult.fromJson(item))
          .toList())
          .toList(),
      tripTypeDetails: json?['tripTypeDetails'] != null
          ? TripTypeDetails.fromJson(json!['tripTypeDetails'])
          : null,    );
  }

  Map<String, dynamic> toJson() => {
    'result': result.map((inner) => inner.map((e) => e.toJson()).toList()).toList(),
    'tripTypeDetails': tripTypeDetails?.toJson(),
  };
}

class GlobalResult {
  final GlobalTripDetails? tripDetails;
  final GlobalFareDetails? fareDetails;
  final GlobalVehicleDetails? vehicleDetails;

  GlobalResult._({
    this.tripDetails,
    this.fareDetails,
    this.vehicleDetails,
  });

  factory GlobalResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('pickupDateTime')) {
      return GlobalResult._(tripDetails: GlobalTripDetails.fromJson(json));
    } else if (json.containsKey('baseFare')) {
      return GlobalResult._(fareDetails: GlobalFareDetails.fromJson(json));
    } else if (json.containsKey('carCategoryName')) {
      return GlobalResult._(vehicleDetails: GlobalVehicleDetails.fromJson(json));
    }
    return GlobalResult._();
  }

  Map<String, dynamic> toJson() {
    if (tripDetails != null) return tripDetails!.toJson();
    if (fareDetails != null) return fareDetails!.toJson();
    if (vehicleDetails != null) return vehicleDetails!.toJson();
    return {};
  }
}

class GlobalTripDetails {
  final String baseCurrency;
  final String pickupDateTime;
  final String dropDateTime;
  final num totalFare;
  final String previousTripCode;
  final num currentTripCode;
  final Location source;
  final Location destination;
  final num totalDistance;
  final num totalTime;
  final String timeZone;

  GlobalTripDetails({
    required this.baseCurrency,
    required this.pickupDateTime,
    required this.dropDateTime,
    required this.totalFare,
    required this.previousTripCode,
    required this.currentTripCode,
    required this.source,
    required this.destination,
    required this.totalDistance,
    required this.totalTime,
    required this.timeZone,
  });

  factory GlobalTripDetails.fromJson(Map<String, dynamic> json) {
    return GlobalTripDetails(
      baseCurrency: json['baseCurrency'],
      pickupDateTime: json['pickupDateTime'],
      dropDateTime: json['dropDateTime'],
      totalFare: json['totalFare'],
      previousTripCode: json['previousTripCode'],
      currentTripCode: json['currentTripCode'],
      source: Location.fromJson(json['source']),
      destination: Location.fromJson(json['destination']),
      totalDistance: json['totalDistance'],
      totalTime: json['totalTime'],
      timeZone: json['timeZone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'baseCurrency': baseCurrency,
    'pickupDateTime': pickupDateTime,
    'dropDateTime': dropDateTime,
    'totalFare': totalFare,
    'previousTripCode': previousTripCode,
    'currentTripCode': currentTripCode,
    'source': source.toJson(),
    'destination': destination.toJson(),
    'totalDistance': totalDistance,
    'totalTime': totalTime,
    'timeZone': timeZone,
  };
}

class GlobalFareDetails {
  final String? id;
  final String? fuelType;
  final String? vehicleCategory;
  final String? destination;
  final String? source;
  final String? tripType;
  final num? airportDropCharge;
  final num? airportPickCharge;
  final List<AirportWaitingCharge>? airportWaitingCharges;
  final num? baseFare;
  final num? baseKm;
  final num? congestionCharge;
  final String? createdAt;
  final num? duration;
  final num? extraFare;
  final num? freeWaitingTime;
  final bool? isActive;
  final num? perKmCharge;
  final String? updatedAt;
  final num? waitingCharge;
  final num? waitingInterval;
  final List<Slab>? slab;

  GlobalFareDetails({
    this.id,
    this.fuelType,
    this.vehicleCategory,
    this.destination,
    this.source,
    this.tripType,
    this.airportDropCharge,
    this.airportPickCharge,
    this.airportWaitingCharges,
    this.baseFare,
    this.baseKm,
    this.congestionCharge,
    this.createdAt,
    this.duration,
    this.extraFare,
    this.freeWaitingTime,
    this.isActive,
    this.perKmCharge,
    this.updatedAt,
    this.waitingCharge,
    this.waitingInterval,
    this.slab,
  });

  factory GlobalFareDetails.fromJson(Map<String, dynamic> json) {
    return GlobalFareDetails(
      id: json['_id'],
      fuelType: json['fuelType'],
      vehicleCategory: json['vehicleCategory'],
      destination: json['destination'],
      source: json['source'],
      tripType: json['tripType'],
      airportDropCharge: (json['airportDropCharge'] ?? 0).toDouble(),
      airportPickCharge: (json['airportPickCharge'] ?? 0).toDouble(),
      airportWaitingCharges: json['airportWaitingCharges'] != null
          ? (json['airportWaitingCharges'] as List)
          .map((e) => AirportWaitingCharge.fromJson(e))
          .toList()
          : null,
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      baseKm: json['baseKm'],
      congestionCharge: (json['congestionCharge'] ?? 0).toDouble(),
      createdAt: json['createdAt'],
      duration: (json['duration'] ?? 0).toDouble(),
      extraFare: (json['extraFare'] ?? 0).toDouble(),
      freeWaitingTime: json['freeWaitingTime'],
      isActive: json['isActive'],
      perKmCharge: (json['perKmCharge'] ?? 0).toDouble(),
      updatedAt: json['updatedAt'],
      waitingCharge: (json['waitingCharge'] ?? 0).toDouble(),
      waitingInterval: json['waitingInterval'],
      slab: json['slab'] != null
          ? (json['slab'] as List).map((e) => Slab.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "_id": id,
      "fuelType": fuelType,
      "vehicleCategory": vehicleCategory,
      "destination": destination,
      "source": source,
      "tripType": tripType,
      "airportDropCharge": airportDropCharge,
      "airportPickCharge": airportPickCharge,
      "airportWaitingCharges": airportWaitingCharges?.map((e) => e.toJson()).toList(),
      "baseFare": baseFare,
      "baseKm": baseKm,
      "congestionCharge": congestionCharge,
      "createdAt": createdAt,
      "duration": duration,
      "extraFare": extraFare,
      "freeWaitingTime": freeWaitingTime,
      "isActive": isActive,
      "perKmCharge": perKmCharge,
      "updatedAt": updatedAt,
      "waitingCharge": waitingCharge,
      "waitingInterval": waitingInterval,
    };

    if (slab != null) {
      data['slab'] = slab!.map((e) => e.toJson()).toList();
    }

    return data;
  }
}

class Slab {
  final String? id;
  final num? maxKm;
  final num? minKm;
  final num? ratePerKM;

  Slab({
    this.id,
    this.maxKm,
    this.minKm,
    this.ratePerKM,
  });

  factory Slab.fromJson(Map<String, dynamic> json) {
    return Slab(
      id: json['_id'],
      maxKm: json['maxKm'],
      minKm: json['minKm'],
      ratePerKM: (json['ratePerKM'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'maxKm': maxKm,
    'minKm': minKm,
    'ratePerKM': ratePerKM,
  };
}



class AirportWaitingCharge {
  final num minTime;
  final num maxTime;
  final num charge;
  final String id;

  AirportWaitingCharge({
    required this.minTime,
    required this.maxTime,
    required this.charge,
    required this.id,
  });

  factory AirportWaitingCharge.fromJson(Map<String, dynamic> json) {
    return AirportWaitingCharge(
      minTime: json['minTime'],
      maxTime: json['maxTime'],
      charge: (json['charge'] ?? 0).toDouble(),
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'minTime': minTime,
    'maxTime': maxTime,
    'charge': charge,
    '_id': id,
  };
}

class GlobalVehicleDetails {
  final String? checkInLuggageCapacity;
  final String? checkInTooltip;
  final num ratings;
  final String id;
  final String carCategoryName;
  final String countryName;
  final String filterCategory;
  final String fuelType;
  final num cabinLuggageCapacity;
  final String cabinTooltip;
  final String createdAt;
  final List<String> extraArray;
  final List<String> extras;
  final num passengerCapacity;
  final String title;
  final String updatedAt;
  final String vehicleImageLink;
  final num checkinLuggageCapacity;
  final String checkinTooltip;
  final num rating;
  final num reviews;

  GlobalVehicleDetails({
    this.checkInLuggageCapacity,
    this.checkInTooltip,
    required this.ratings,
    required this.id,
    required this.carCategoryName,
    required this.countryName,
    required this.filterCategory,
    required this.fuelType,
    required this.cabinLuggageCapacity,
    required this.cabinTooltip,
    required this.createdAt,
    required this.extraArray,
    required this.extras,
    required this.passengerCapacity,
    required this.title,
    required this.updatedAt,
    required this.vehicleImageLink,
    required this.checkinLuggageCapacity,
    required this.checkinTooltip,
    required this.rating,
    required this.reviews,
  });

  factory GlobalVehicleDetails.fromJson(Map<String, dynamic> json) {
    return GlobalVehicleDetails(
      checkInLuggageCapacity: json['checkInluggageCapacity'],
      checkInTooltip: json['checkInTooltip'],
      ratings: (json['ratings'] ?? 0).toDouble(),
      id: json['_id'],
      carCategoryName: json['carCategoryName'],
      countryName: json['countryName'],
      filterCategory: json['filterCategory'],
      fuelType: json['fuelType'],
      cabinLuggageCapacity: json['cabinLuggageCapacity'],
      cabinTooltip: json['cabinTooltip'],
      createdAt: json['createdAt'],
      extraArray: List<String>.from(json['extraArray']),
      extras: List<String>.from(json['extras']),
      passengerCapacity: json['passengerCapacity'],
      title: json['title'],
      updatedAt: json['updatedAt'],
      vehicleImageLink: json['vehicleImageLink'].trim(),
      checkinLuggageCapacity: json['checkinLuggageCapacity'],
      checkinTooltip: json['checkinTooltip'],
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'],
    );
  }

  Map<String, dynamic> toJson() => {
    'checkInluggageCapacity': checkInLuggageCapacity,
    'checkInTooltip': checkInTooltip,
    'ratings': ratings,
    '_id': id,
    'carCategoryName': carCategoryName,
    'countryName': countryName,
    'filterCategory': filterCategory,
    'fuelType': fuelType,
    'cabinLuggageCapacity': cabinLuggageCapacity,
    'cabinTooltip': cabinTooltip,
    'createdAt': createdAt,
    'extraArray': extraArray,
    'extras': extras,
    'passengerCapacity': passengerCapacity,
    'title': title,
    'updatedAt': updatedAt,
    'vehicleImageLink': vehicleImageLink,
    'checkinLuggageCapacity': checkinLuggageCapacity,
    'checkinTooltip': checkinTooltip,
    'rating': rating,
    'reviews': reviews,
  };
}

class Location {
  final String title;
  final String lat;
  final String lng;

  Location({
    required this.title,
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    title: json['title'],
    lat: json['lat'],
    lng: json['lng'],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'lat': lat,
    'lng': lng,
  };
}

class TripTypeDetails {
  final String basicTripType;
  final String tripType;
  final String airportType;

  TripTypeDetails({
    required this.basicTripType,
    required this.tripType,
    required this.airportType,
  });

  factory TripTypeDetails.fromJson(Map<String, dynamic> json) {
    return TripTypeDetails(
      basicTripType: json['basic_trip_type'],
      tripType: json['trip_type'],
      airportType: json['airport_type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'basic_trip_type': basicTripType,
    'trip_type': tripType,
    'airport_type': airportType,
  };
}