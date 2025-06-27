class IndiaResponse {
  final Result? result;

  IndiaResponse({this.result});

  factory IndiaResponse.fromJson(Map<String, dynamic> json) {
    return IndiaResponse(
      result: json['result'] != null ? Result.fromJson(json['result']) : null,
    );
  }
}

class Result {
  final Inventory? inventory;
  final TripType? tripType;
  final OfferObject? offerObject;

  Result({this.inventory, this.tripType, this.offerObject});

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      inventory:
      json['inventory'] != null ? Inventory.fromJson(json['inventory']) : null,
      tripType:
      json['tripType'] != null ? TripType.fromJson(json['tripType']) : null,
      offerObject: json['offerObject'] != null
          ? OfferObject.fromJson(json['offerObject'])
          : null,
    );
  }
}

class Inventory {
  final num? distanceBooked;
  final bool? isInstantSearch;
  final bool? isInstantAvailable;
  final DateTime? startTime;
  final bool? isPartPaymentAllowed;
  final String? communicationType;
  final String? verificationType;
  final List<CarType>? carTypes;

  Inventory({
    this.distanceBooked,
    this.isInstantSearch,
    this.isInstantAvailable,
    this.startTime,
    this.isPartPaymentAllowed,
    this.communicationType,
    this.verificationType,
    this.carTypes,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      distanceBooked: json['distance_booked'],
      isInstantSearch: json['is_instant_search'],
      isInstantAvailable: json['is_instant_available'],
      startTime:
      json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      isPartPaymentAllowed: json['is_part_payment_allowed'],
      communicationType: json['communication_type'],
      verificationType: json['verification_type'],
      carTypes: (json['car_types'] as List<dynamic>?)
          ?.map((e) => CarType.fromJson(e))
          .toList(),
    );
  }
}

class CarType {
  final String? routeId;
  final String? skuId;
  final Location? source;
  final String? type;
  final String? subcategory;
  final String? combustionType;
  final bool? carrier;
  final String? makeYearType;
  final num? baseKm;
  final List<String>? flags;
  final String? cancellationRule;
  final String? model;
  final String? tripType;
  final Amenities? amenities;
  final FareDetails? fareDetails;
  final List<Extra>? extrasIdArray;
  final Rating? rating;
  final num? seats;
  final String? luggageCapacity;
  final bool? isActive;
  final bool? pet;
  final String? carTagLine;
  final num? fakePercentageOff;

  CarType({
    this.routeId,
    this.skuId,
    this.source,
    this.type,
    this.subcategory,
    this.combustionType,
    this.carrier,
    this.makeYearType,
    this.baseKm,
    this.flags,
    this.cancellationRule,
    this.model,
    this.tripType,
    this.amenities,
    this.fareDetails,
    this.extrasIdArray,
    this.rating,
    this.seats,
    this.luggageCapacity,
    this.isActive,
    this.pet,
    this.carTagLine,
    this.fakePercentageOff,
  });

  factory CarType.fromJson(Map<String, dynamic> json) {
    return CarType(
      routeId: json['route_id'],
      skuId: json['sku_id'],
      source: json['source'] != null ? Location.fromJson(json['source']) : null,
      type: json['type'],
      subcategory: json['subcategory'],
      combustionType: json['combustion_type'],
      carrier: json['carrier'],
      makeYearType: json['make_year_type'],
      baseKm: json['base_km'],
      flags: (json['flags'] as List?)?.map((e) => e.toString()).toList(),
      cancellationRule: json['cancellation_rule'],
      model: json['model'],
      tripType: json['trip_type'],
      amenities: json['amenities'] != null
          ? Amenities.fromJson(json['amenities'])
          : null,
      fareDetails: json['fare_details'] != null
          ? FareDetails.fromJson(json['fare_details'])
          : null,
      extrasIdArray: (json['extrasIdArray'] as List?)
          ?.map((e) => Extra.fromJson(e))
          .toList(),
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      seats: json['seats'],
      luggageCapacity: json['luggageCapacity'],
      isActive: json['isActive'],
      pet: json['pet'],
      carTagLine: json['carTagLine'],
      fakePercentageOff: json['fakePercentageOff'],
    );
  }
}

class TripType {
  final Location? source;
  final Location? destination;
  final String? tripType;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? searchTags;
  final num? oneWayDistance;
  final bool? isInstantSearch;
  final TripTypeDetails? tripTypeDetails;
  final String? previousTripCode;
  final String? currentTripCode;
  final String? searchId;
  final num? distanceBooked;

  TripType({
    this.source,
    this.destination,
    this.tripType,
    this.startTime,
    this.endTime,
    this.searchTags,
    this.oneWayDistance,
    this.isInstantSearch,
    this.tripTypeDetails,
    this.previousTripCode,
    this.currentTripCode,
    this.searchId,
    this.distanceBooked,
  });

  factory TripType.fromJson(Map<String, dynamic> json) {
    return TripType(
      source:
      json['source'] != null ? Location.fromJson(json['source']) : null,
      destination: json['destination'] != null
          ? Location.fromJson(json['destination'])
          : null,
      tripType: json['trip_type'],
      startTime:
      json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime:
      json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      searchTags:
      (json['search_tags'] as List?)?.map((e) => e.toString()).toList(),
      oneWayDistance: json['one_way_distance'],
      isInstantSearch: json['is_instant_search'],
      tripTypeDetails: json['trip_type_details'] != null
          ? TripTypeDetails.fromJson(json['trip_type_details'])
          : null,
      previousTripCode: json['previousTripCode'],
      currentTripCode: json['currentTripCode'],
      searchId: json['search_id'],
      distanceBooked: json['distance_booked'],
    );
  }
}

class Location {
  final String? address;
  final num? latitude;
  final num? longitude;
  final String? city;

  Location({this.address, this.latitude, this.longitude, this.city});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'],
    );
  }
}

class Amenities {
  final Features? features;

  Amenities({this.features});

  factory Amenities.fromJson(Map<String, dynamic> json) {
    return Amenities(
      features:
      json['features'] != null ? Features.fromJson(json['features']) : null,
    );
  }
}

class Features {
  final List<String>? vehicleIcons;
  final List<String>? vehicle;
  final List<String>? driver;
  final List<String>? services;

  Features({this.vehicleIcons, this.vehicle, this.driver, this.services});

  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      vehicleIcons:
      (json['vehicle_icons'] as List?)?.map((e) => e.toString()).toList(),
      vehicle: (json['vehicle'] as List?)?.map((e) => e.toString()).toList(),
      driver: (json['driver'] as List?)?.map((e) => e.toString()).toList(),
      services: (json['services'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

class FareDetails {
  final num? sellerDiscount;
  final num? perKmCharge;
  final num? perKmExtraCharge;
  final num? totalDriverCharges;
  final num? baseFare;
  final ExtraTimeFare? extraTimeFare;
  final ExtraCharges? extraCharges;

  FareDetails({
    this.sellerDiscount,
    this.perKmCharge,
    this.perKmExtraCharge,
    this.totalDriverCharges,
    this.baseFare,
    this.extraTimeFare,
    this.extraCharges,
  });

  factory FareDetails.fromJson(Map<String, dynamic> json) {
    return FareDetails(
      sellerDiscount: json['seller_discount'],
      perKmCharge: json['per_km_charge'],
      perKmExtraCharge: json['per_km_extra_charge'],
      totalDriverCharges: json['total_driver_charges'],
      baseFare: json['base_fare'],
      extraTimeFare: json['extra_time_fare'] != null
          ? ExtraTimeFare.fromJson(json['extra_time_fare'])
          : null,
      extraCharges: json['extra_charges'] != null
          ? ExtraCharges.fromJson(json['extra_charges'])
          : null,
    );
  }
}

class ExtraTimeFare {
  final num? rate;
  final num? applicableTime;

  ExtraTimeFare({this.rate, this.applicableTime});

  factory ExtraTimeFare.fromJson(Map<String, dynamic> json) {
    return ExtraTimeFare(
      rate: json['rate'],
      applicableTime: json['applicable_time'],
    );
  }
}

class ExtraCharges {
  final ChargeDetail? nightCharges;
  final ChargeDetail? tollCharges;
  final ChargeDetail? stateTax;
  final ChargeDetail? parkingCharges;
  final WaitingCharges? waitingCharges;

  ExtraCharges({
    this.nightCharges,
    this.tollCharges,
    this.stateTax,
    this.parkingCharges,
    this.waitingCharges,
  });

  factory ExtraCharges.fromJson(Map<String, dynamic> json) {
    return ExtraCharges(
      nightCharges: ChargeDetail.fromJson(json['night_charges']),
      tollCharges: ChargeDetail.fromJson(json['toll_charges']),
      stateTax: ChargeDetail.fromJson(json['state_tax']),
      parkingCharges: ChargeDetail.fromJson(json['parking_charges']),
      waitingCharges: WaitingCharges.fromJson(json['waiting_charges']),
    );
  }
}

class ChargeDetail {
  final num? amount;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;
  final num? applicableTimeFrom;
  final num? applicableTimeTill;
  final bool? isApplicable;

  ChargeDetail({
    this.amount,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
    this.applicableTimeFrom,
    this.applicableTimeTill,
    this.isApplicable,
  });

  factory ChargeDetail.fromJson(Map<String, dynamic> json) {
    return ChargeDetail(
      amount: json['amount'],
      isIncludedInBaseFare: json['is_included_in_base_fare'],
      isIncludedInGrandTotal: json['is_included_in_grand_total'],
      applicableTimeFrom: json['applicable_time_from'],
      applicableTimeTill: json['applicable_time_till'],
      isApplicable: json['is_applicable'],
    );
  }
}

class WaitingCharges extends ChargeDetail {
  final num? freeWaitingTime;
  final num? applicableTime;

  WaitingCharges({
    num? amount,
    bool? isIncludedInBaseFare,
    bool? isIncludedInGrandTotal,
    bool? isApplicable,
    this.freeWaitingTime,
    this.applicableTime,
  }) : super(
      amount: amount,
      isIncludedInBaseFare: isIncludedInBaseFare,
      isIncludedInGrandTotal: isIncludedInGrandTotal,
      isApplicable: isApplicable);

  factory WaitingCharges.fromJson(Map<String, dynamic> json) {
    return WaitingCharges(
      amount: json['amount'],
      isIncludedInBaseFare: json['is_included_in_base_fare'],
      isIncludedInGrandTotal: json['is_included_in_grand_total'],
      isApplicable: json['is_applicable'],
      freeWaitingTime: json['free_waiting_time'],
      applicableTime: json['applicable_time'],
    );
  }
}

class Extra {
  final Price? price;
  final String? id;
  final String? countryName;
  final String? name;
  final String? title;
  final String? img;
  final String? description;
  final bool? isActive;
  final String? baseCurrency;

  Extra({
    this.price,
    this.id,
    this.countryName,
    this.name,
    this.title,
    this.img,
    this.description,
    this.isActive,
    this.baseCurrency,
  });

  factory Extra.fromJson(Map<String, dynamic> json) {
    return Extra(
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      id: json['_id'],
      countryName: json['countryName'],
      name: json['name'],
      title: json['title'],
      img: json['img'],
      description: json['description'],
      isActive: json['isActive'],
      baseCurrency: json['baseCurrency'],
    );
  }
}

class Price {
  final num? daily;
  final num? maximum;

  Price({this.daily, this.maximum});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      daily: json['daily'],
      maximum: json['maximum'],
    );
  }
}

class Rating {
  final String? tag;
  final num? ratePoints;

  Rating({this.tag, this.ratePoints});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      tag: json['tag'],
      ratePoints: (json['ratePoints'] as num?)?.toDouble(),
    );
  }
}

class TripTypeDetails {
  final String? basicTripType;
  final String? airportType;

  TripTypeDetails({this.basicTripType, this.airportType});

  factory TripTypeDetails.fromJson(Map<String, dynamic> json) {
    return TripTypeDetails(
      basicTripType: json['basic_trip_type'],
      airportType: json['airport_type'],
    );
  }
}

class OfferObject {
  final bool? applicable;
  final String? message;

  OfferObject({this.applicable, this.message});

  factory OfferObject.fromJson(Map<String, dynamic> json) {
    return OfferObject(
      applicable: json['applicable'],
      message: json['message'],
    );
  }
}