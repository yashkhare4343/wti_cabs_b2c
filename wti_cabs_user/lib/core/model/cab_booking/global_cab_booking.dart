class GlobalBookingFlat {
  double? totalFare;
  int? totalDistance;
  FareBreakUpDetails? fareBreakUpDetails;
  VehicleDetails? vehicleDetails;
  String? baseCurrency;
  TripTypeDetails? tripTypeDetails;

  GlobalBookingFlat({
    this.totalFare,
    this.totalDistance,
    this.fareBreakUpDetails,
    this.vehicleDetails,
    this.baseCurrency,
    this.tripTypeDetails,
  });

  factory GlobalBookingFlat.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! Map<String, dynamic>) return GlobalBookingFlat();

    return GlobalBookingFlat(
      totalFare: (result['totalFare'] as num?)?.toDouble(),
      totalDistance: (result['totalDistance'] as num?)?.toInt(),
      fareBreakUpDetails: result['fareBreakUpDetails'] != null
          ? FareBreakUpDetails.fromJson(result['fareBreakUpDetails'])
          : null,
      vehicleDetails: result['vehicleDetails'] != null
          ? VehicleDetails.fromJson(result['vehicleDetails'])
          : null,
      baseCurrency: result['baseCurrency'],
      tripTypeDetails: json['tripTypeDetails'] != null
          ? TripTypeDetails.fromJson(json['tripTypeDetails'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalFare': totalFare,
    'totalDistance': totalDistance,
    'fareBreakUpDetails': fareBreakUpDetails?.toJson(),
    'vehicleDetails': vehicleDetails?.toJson(),
    'baseCurrency': baseCurrency,
    'tripTypeDetails': tripTypeDetails?.toJson(),
  };
}
class FareBreakUpDetails {
  String? id;
  String? fuelType;
  String? vehicleCategory;
  String? destination;
  String? source;
  String? tripType;
  double? airportDropCharge;
  double? airportPickCharge;
  List<AirportWaitingCharge>? airportWaitingCharges;
  double? baseFare;
  int? baseKm;
  double? congestionCharge;
  String? createdAt;
  double? duration;
  double? extraFare;
  int? freeWaitingTime;
  bool? isActive;
  double? perKmCharge;
  String? updatedAt;
  double? waitingCharge;
  int? waitingInterval;

  FareBreakUpDetails({
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
  });

  factory FareBreakUpDetails.fromJson(Map<String, dynamic> json) {
    return FareBreakUpDetails(
      id: json['_id'],
      fuelType: json['fuelType'],
      vehicleCategory: json['vehicleCategory'],
      destination: json['destination'],
      source: json['source'],
      tripType: json['tripType'],
      airportDropCharge: (json['airportDropCharge'] as num?)?.toDouble(),
      airportPickCharge: (json['airportPickCharge'] as num?)?.toDouble(),
      airportWaitingCharges: (json['airportWaitingCharges'] as List<dynamic>?)
          ?.map((e) => AirportWaitingCharge.fromJson(e))
          .toList(),
      baseFare: (json['baseFare'] as num?)?.toDouble(),
      baseKm: json['baseKm'],
      congestionCharge: (json['congestionCharge'] as num?)?.toDouble(),
      createdAt: json['createdAt'],
      duration: (json['duration'] as num?)?.toDouble(),
      extraFare: (json['extraFare'] as num?)?.toDouble(),
      freeWaitingTime: json['freeWaitingTime'],
      isActive: json['isActive'],
      perKmCharge: (json['perKmCharge'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'],
      waitingCharge: (json['waitingCharge'] as num?)?.toDouble(),
      waitingInterval: json['waitingInterval'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fuelType': fuelType,
    'vehicleCategory': vehicleCategory,
    'destination': destination,
    'source': source,
    'tripType': tripType,
    'airportDropCharge': airportDropCharge,
    'airportPickCharge': airportPickCharge,
    'airportWaitingCharges':
    airportWaitingCharges?.map((e) => e.toJson()).toList(),
    'baseFare': baseFare,
    'baseKm': baseKm,
    'congestionCharge': congestionCharge,
    'createdAt': createdAt,
    'duration': duration,
    'extraFare': extraFare,
    'freeWaitingTime': freeWaitingTime,
    'isActive': isActive,
    'perKmCharge': perKmCharge,
    'updatedAt': updatedAt,
    'waitingCharge': waitingCharge,
    'waitingInterval': waitingInterval,
  };
}
class AirportWaitingCharge {
  int? minTime;
  int? maxTime;
  double? charge;
  String? id;

  AirportWaitingCharge({
    this.minTime,
    this.maxTime,
    this.charge,
    this.id,
  });

  factory AirportWaitingCharge.fromJson(Map<String, dynamic> json) {
    return AirportWaitingCharge(
      minTime: json['minTime'],
      maxTime: json['maxTime'],
      charge: (json['charge'] as num?)?.toDouble(),
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
class VehicleDetails {
  int? checkinLuggageCapacity;
  String? checkinTooltip;
  double? ratings;
  String? id;
  String? carCategoryName;
  String? countryName;
  String? filterCategory;
  String? fuelType;
  int? cabinLuggageCapacity;
  String? cabinTooltip;
  String? createdAt;
  List<ExtraArrayItem>? extraArray;
  List<String>? extras;
  int? passengerCapacity;
  String? title;
  String? updatedAt;
  String? vehicleImageLink;
  double? rating;
  int? reviews;

  VehicleDetails({
    this.checkinLuggageCapacity,
    this.checkinTooltip,
    this.ratings,
    this.id,
    this.carCategoryName,
    this.countryName,
    this.filterCategory,
    this.fuelType,
    this.cabinLuggageCapacity,
    this.cabinTooltip,
    this.createdAt,
    this.extraArray,
    this.extras,
    this.passengerCapacity,
    this.title,
    this.updatedAt,
    this.vehicleImageLink,
    this.rating,
    this.reviews,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      checkinLuggageCapacity: json['checkinLuggageCapacity'],
      checkinTooltip: json['checkinTooltip'],
      ratings: (json['ratings'] as num?)?.toDouble(),
      id: json['_id'],
      carCategoryName: json['carCategoryName'],
      countryName: json['countryName'],
      filterCategory: json['filterCategory'],
      fuelType: json['fuelType'],
      cabinLuggageCapacity: json['cabinLuggageCapacity'],
      cabinTooltip: json['cabinTooltip'],
      createdAt: json['createdAt'],
      extraArray: (json['extraArray'] as List<dynamic>?)
          ?.map((e) => ExtraArrayItem.fromJson(e))
          .toList(),
      extras: (json['extras'] as List?)?.map((e) => e.toString()).toList(),
      passengerCapacity: json['passengerCapacity'],
      title: json['title'],
      updatedAt: json['updatedAt'],
      vehicleImageLink: json['vehicleImageLink'],
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: json['reviews'],
    );
  }

  Map<String, dynamic> toJson() => {
    'checkinLuggageCapacity': checkinLuggageCapacity,
    'checkinTooltip': checkinTooltip,
    'ratings': ratings,
    '_id': id,
    'carCategoryName': carCategoryName,
    'countryName': countryName,
    'filterCategory': filterCategory,
    'fuelType': fuelType,
    'cabinLuggageCapacity': cabinLuggageCapacity,
    'cabinTooltip': cabinTooltip,
    'createdAt': createdAt,
    'extraArray': extraArray?.map((e) => e.toJson()).toList(),
    'extras': extras,
    'passengerCapacity': passengerCapacity,
    'title': title,
    'updatedAt': updatedAt,
    'vehicleImageLink': vehicleImageLink,
    'rating': rating,
    'reviews': reviews,
  };
}
class ExtraArrayItem {
  Price? price;
  String? id;
  String? countryName;
  String? name;
  String? driveType;
  String? title;
  String? img;
  String? description;
  String? baseCurrency;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? index;
  int? v;

  ExtraArrayItem({
    this.price,
    this.id,
    this.countryName,
    this.name,
    this.driveType,
    this.title,
    this.img,
    this.description,
    this.baseCurrency,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.index,
    this.v,
  });

  factory ExtraArrayItem.fromJson(Map<String, dynamic> json) {
    return ExtraArrayItem(
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      id: json['_id'],
      countryName: json['countryName'],
      name: json['name'],
      driveType: json['driveType'],
      title: json['title'],
      img: json['img'],
      description: json['description'],
      baseCurrency: json['baseCurrency'],
      isActive: json['isActive'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      index: json['id'],
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() => {
    'price': price?.toJson(),
    '_id': id,
    'countryName': countryName,
    'name': name,
    'driveType': driveType,
    'title': title,
    'img': img,
    'description': description,
    'baseCurrency': baseCurrency,
    'isActive': isActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'id': index,
    '__v': v,
  };
}
class Price {
  double? daily;
  double? maximum;

  Price({this.daily, this.maximum});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      daily: (json['daily'] as num?)?.toDouble(),
      maximum: (json['maximum'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'daily': daily,
    'maximum': maximum,
  };
}
class TripTypeDetails {
  String? basicTripType;
  String? tripType;
  String? airportType;

  TripTypeDetails({
    this.basicTripType,
    this.tripType,
    this.airportType,
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
