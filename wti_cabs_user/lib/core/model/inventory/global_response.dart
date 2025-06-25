class GlobalResponse {
  final Result? result;

  GlobalResponse({this.result});

  factory GlobalResponse.fromJson(Map<String, dynamic> json) =>
      GlobalResponse(result: Result.fromJson(json['result'] ?? {}));
}

class Result {
  final Inventory? inventory;
  final TripType? tripType;
  final OfferObject? offerObject;

  Result({this.inventory, this.tripType, this.offerObject});

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    inventory: Inventory.fromJson(json['inventory'] ?? {}),
    tripType: TripType.fromJson(json['tripType'] ?? {}),
    offerObject: OfferObject.fromJson(json['offerObject'] ?? {}),
  );
}

class Inventory {
  final int? distanceBooked;
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

  factory Inventory.fromJson(Map<String, dynamic> json) => Inventory(
    distanceBooked: json['distance_booked'],
    isInstantSearch: json['is_instant_search'],
    isInstantAvailable: json['is_instant_available'],
    startTime: DateTime.tryParse(json['start_time'] ?? ''),
    isPartPaymentAllowed: json['is_part_payment_allowed'],
    communicationType: json['communication_type'],
    verificationType: json['verification_type'],
    carTypes: (json['car_types'] as List<dynamic>?)
        ?.map((e) => CarType.fromJson(e))
        .toList(),
  );
}

class CarType {
  final String? routeId;
  final String? skuId;
  final Place? source;
  final String? type;
  final String? subcategory;
  final String? combustionType;
  final bool? carrier;
  final String? makeYearType;
  final int? baseKm;
  final List<String>? flags;
  final String? cancellationRule;
  final String? model;
  final String? tripType;
  final Amenities? amenities;
  final FareDetails? fareDetails;
  final List<Extra>? extrasIdArray;
  final Rating? rating;
  final int? seats;
  final String? luggageCapacity;
  final bool? isActive;
  final bool? pet;
  final String? carTagLine;
  final int? fakePercentageOff;

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

  factory CarType.fromJson(Map<String, dynamic> json) => CarType(
    routeId: json['route_id'],
    skuId: json['sku_id'],
    source: Place.fromJson(json['source'] ?? {}),
    type: json['type'],
    subcategory: json['subcategory'],
    combustionType: json['combustion_type'],
    carrier: json['carrier'],
    makeYearType: json['make_year_type'],
    baseKm: json['base_km'],
    flags: List<String>.from(json['flags'] ?? []),
    cancellationRule: json['cancellation_rule'],
    model: json['model'],
    tripType: json['trip_type'],
    amenities: Amenities.fromJson(json['amenities'] ?? {}),
    fareDetails: FareDetails.fromJson(json['fare_details'] ?? {}),
    extrasIdArray: (json['extrasIdArray'] as List<dynamic>?)
        ?.map((e) => Extra.fromJson(e))
        .toList(),
    rating: Rating.fromJson(json['rating'] ?? {}),
    seats: json['seats'],
    luggageCapacity: json['luggageCapacity'],
    isActive: json['isActive'],
    pet: json['pet'],
    carTagLine: json['carTagLine'],
    fakePercentageOff: json['fakePercentageOff'],
  );
}

class Place {
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? city;

  Place({this.address, this.latitude, this.longitude, this.city});

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    address: json['address'],
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    city: json['city'],
  );
}

class Amenities {
  final Features? features;

  Amenities({this.features});

  factory Amenities.fromJson(Map<String, dynamic> json) =>
      Amenities(features: Features.fromJson(json['features'] ?? {}));
}

class Features {
  final List<String>? vehicleIcons;
  final List<String>? vehicle;
  final List<String>? driver;
  final List<String>? services;

  Features({this.vehicleIcons, this.vehicle, this.driver, this.services});

  factory Features.fromJson(Map<String, dynamic> json) => Features(
    vehicleIcons: List<String>.from(json['vehicle_icons'] ?? []),
    vehicle: List<String>.from(json['vehicle'] ?? []),
    driver: List<String>.from(json['driver'] ?? []),
    services: List<String>.from(json['services'] ?? []),
  );
}

class FareDetails {
  final int? sellerDiscount;
  final int? perKmCharge;
  final int? perKmExtraCharge;
  final int? totalDriverCharges;
  final int? baseFare;
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

  factory FareDetails.fromJson(Map<String, dynamic> json) => FareDetails(
    sellerDiscount: json['seller_discount'],
    perKmCharge: json['per_km_charge'],
    perKmExtraCharge: json['per_km_extra_charge'],
    totalDriverCharges: json['total_driver_charges'],
    baseFare: json['base_fare'],
    extraTimeFare: ExtraTimeFare.fromJson(json['extra_time_fare'] ?? {}),
    extraCharges: ExtraCharges.fromJson(json['extra_charges'] ?? {}),
  );
}

class ExtraTimeFare {
  final int? rate;
  final int? applicableTime;

  ExtraTimeFare({this.rate, this.applicableTime});

  factory ExtraTimeFare.fromJson(Map<String, dynamic> json) => ExtraTimeFare(
    rate: json['rate'],
    applicableTime: json['applicable_time'],
  );
}

class ExtraCharges {
  final Charge? nightCharges;
  final Charge? tollCharges;
  final Charge? stateTax;
  final Charge? parkingCharges;
  final WaitingCharges? waitingCharges;

  ExtraCharges({
    this.nightCharges,
    this.tollCharges,
    this.stateTax,
    this.parkingCharges,
    this.waitingCharges,
  });

  factory ExtraCharges.fromJson(Map<String, dynamic> json) => ExtraCharges(
    nightCharges: Charge.fromJson(json['night_charges'] ?? {}),
    tollCharges: Charge.fromJson(json['toll_charges'] ?? {}),
    stateTax: Charge.fromJson(json['state_tax'] ?? {}),
    parkingCharges: Charge.fromJson(json['parking_charges'] ?? {}),
    waitingCharges:
    WaitingCharges.fromJson(json['waiting_charges'] ?? {}),
  );
}

class Charge {
  final int? amount;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;
  final int? applicableTimeFrom;
  final int? applicableTimeTill;
  final bool? isApplicable;

  Charge({
    this.amount,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
    this.applicableTimeFrom,
    this.applicableTimeTill,
    this.isApplicable,
  });

  factory Charge.fromJson(Map<String, dynamic> json) => Charge(
    amount: json['amount'],
    isIncludedInBaseFare: json['is_included_in_base_fare'],
    isIncludedInGrandTotal: json['is_included_in_grand_total'],
    applicableTimeFrom: json['applicable_time_from'],
    applicableTimeTill: json['applicable_time_till'],
    isApplicable: json['is_applicable'],
  );
}

class WaitingCharges extends Charge {
  final int? freeWaitingTime;
  final int? applicableTime;

  WaitingCharges({
    int? amount,
    bool? isIncludedInBaseFare,
    bool? isIncludedInGrandTotal,
    this.freeWaitingTime,
    this.applicableTime,
    bool? isApplicable,
  }) : super(
      amount: amount,
      isIncludedInBaseFare: isIncludedInBaseFare,
      isIncludedInGrandTotal: isIncludedInGrandTotal,
      isApplicable: isApplicable);

  factory WaitingCharges.fromJson(Map<String, dynamic> json) =>
      WaitingCharges(
        amount: json['amount'],
        freeWaitingTime: json['free_waiting_time'],
        applicableTime: json['applicable_time'],
        isIncludedInBaseFare: json['is_included_in_base_fare'],
        isIncludedInGrandTotal: json['is_included_in_grand_total'],
        isApplicable: json['is_applicable'],
      );
}

class Extra {
  final ExtraPrice? price;
  final String? id;
  final String? name;
  final String? title;
  final String? driveType;
  final String? img;
  final String? description;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? localId;
  final String? countryName;
  final String? baseCurrency;

  Extra({
    this.price,
    this.id,
    this.name,
    this.title,
    this.driveType,
    this.img,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.localId,
    this.countryName,
    this.baseCurrency,
  });

  factory Extra.fromJson(Map<String, dynamic> json) => Extra(
    price: ExtraPrice.fromJson(json['price'] ?? {}),
    id: json['_id'],
    name: json['name'],
    title: json['title'],
    driveType: json['driveType'],
    img: json['img'],
    description: json['description'],
    isActive: json['isActive'],
    createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
    localId: json['id'],
    countryName: json['countryName'],
    baseCurrency: json['baseCurrency'],
  );
}

class ExtraPrice {
  final int? daily;
  final int? maximum;

  ExtraPrice({this.daily, this.maximum});

  factory ExtraPrice.fromJson(Map<String, dynamic> json) => ExtraPrice(
    daily: json['daily'],
    maximum: json['maximum'],
  );
}

class Rating {
  final String? tag;
  final double? ratePoints;

  Rating({this.tag, this.ratePoints});

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    tag: json['tag'],
    ratePoints: (json['ratePoints'] as num?)?.toDouble(),
  );
}

class TripType {
  final Place? source;
  final Place? destination;
  final String? tripType;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? searchTags;
  final int? oneWayDistance;
  final bool? isInstantSearch;
  final List<dynamic>? stopovers;
  final List<dynamic>? mandatoryInclusions;
  final TripTypeDetails? tripTypeDetails;
  final String? previousTripCode;
  final String? currentTripCode;
  final String? searchId;
  final int? distanceBooked;

  TripType({
    this.source,
    this.destination,
    this.tripType,
    this.startTime,
    this.endTime,
    this.searchTags,
    this.oneWayDistance,
    this.isInstantSearch,
    this.stopovers,
    this.mandatoryInclusions,
    this.tripTypeDetails,
    this.previousTripCode,
    this.currentTripCode,
    this.searchId,
    this.distanceBooked,
  });

  factory TripType.fromJson(Map<String, dynamic> json) => TripType(
    source: Place.fromJson(json['source'] ?? {}),
    destination: Place.fromJson(json['destination'] ?? {}),
    tripType: json['trip_type'],
    startTime: DateTime.tryParse(json['start_time'] ?? ''),
    endTime: DateTime.tryParse(json['end_time'] ?? ''),
    searchTags: List<String>.from(json['search_tags'] ?? []),
    oneWayDistance: json['one_way_distance'],
    isInstantSearch: json['is_instant_search'],
    stopovers: json['stopovers'],
    mandatoryInclusions: json['mandatory_inclusions'],
    tripTypeDetails:
    TripTypeDetails.fromJson(json['trip_type_details'] ?? {}),
    previousTripCode: json['previousTripCode'],
    currentTripCode: json['currentTripCode'],
    searchId: json['search_id'],
    distanceBooked: json['distance_booked'],
  );
}

class TripTypeDetails {
  final String? basicTripType;
  final String? airportType;

  TripTypeDetails({this.basicTripType, this.airportType});

  factory TripTypeDetails.fromJson(Map<String, dynamic> json) =>
      TripTypeDetails(
        basicTripType: json['basic_trip_type'],
        airportType: json['airport_type'],
      );
}

class OfferObject {
  final bool? applicable;
  final String? message;

  OfferObject({this.applicable, this.message});

  factory OfferObject.fromJson(Map<String, dynamic> json) => OfferObject(
    applicable: json['applicable'],
    message: json['message'],
  );
}