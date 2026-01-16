class IndiaResponse {
  final Result? result;

  IndiaResponse({this.result});

  factory IndiaResponse.fromJson(Map<String, dynamic> json) {
    return IndiaResponse(
      result: json['result'] != null ? Result.fromJson(json['result']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'inventory': inventory?.toJson(),
      'tripType': tripType?.toJson(),
      'offerObject': offerObject?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'distance_booked': distanceBooked,
      'is_instant_search': isInstantSearch,
      'is_instant_available': isInstantAvailable,
      'start_time': startTime?.toIso8601String(),
      'is_part_payment_allowed': isPartPaymentAllowed,
      'communication_type': communicationType,
      'verification_type': verificationType,
      'car_types': carTypes?.map((e) => e.toJson()).toList(),
    };
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
  final String? carImageUrl;
  final InventoryCoupon? coupon;
  final num? discountedCoupon;

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
    this.carImageUrl,
    this.coupon,
    this.discountedCoupon,
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
      carImageUrl: json['carImageUrl'],
      coupon: json['coupon'] != null
          ? InventoryCoupon.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
      discountedCoupon: json['discountedCoupon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'sku_id': skuId,
      'source': source?.toJson(),
      'type': type,
      'subcategory': subcategory,
      'combustion_type': combustionType,
      'carrier': carrier,
      'make_year_type': makeYearType,
      'base_km': baseKm,
      'flags': flags,
      'cancellation_rule': cancellationRule,
      'model': model,
      'trip_type': tripType,
      'amenities': amenities?.toJson(),
      'fare_details': fareDetails?.toJson(),
      'extrasIdArray': extrasIdArray?.map((e) => e.toJson()).toList(),
      'rating': rating?.toJson(),
      'seats': seats,
      'luggageCapacity': luggageCapacity,
      'isActive': isActive,
      'pet': pet,
      'carTagLine': carTagLine,
      'fakePercentageOff': fakePercentageOff,
      'carImageUrl': carImageUrl,
      'coupon': coupon?.toJson(),
      'discountedCoupon': discountedCoupon,
    };
  }
}

class InventoryCoupon {
  final String? id;
  final bool? couponIsActive;
  final String? codeName;
  final num? codePercentage;
  final num? maximumDiscountAmount;

  InventoryCoupon({
    this.id,
    this.couponIsActive,
    this.codeName,
    this.codePercentage,
    this.maximumDiscountAmount,
  });

  factory InventoryCoupon.fromJson(Map<String, dynamic> json) {
    return InventoryCoupon(
      id: json['_id'] as String?,
      couponIsActive: json['couponIsActive'] as bool?,
      codeName: json['codeName'] as String?,
      codePercentage: json['codePercentage'] as num?,
      maximumDiscountAmount: json['maximumDiscountAmount'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'couponIsActive': couponIsActive,
      'codeName': codeName,
      'codePercentage': codePercentage,
      'maximumDiscountAmount': maximumDiscountAmount,
    };
  }
}

class TripType {
  final Location? source;
  final Location? destination;
  final String? tripType;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? searchTags;
  final String? packageId;
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
    this.packageId,
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
      packageId: json['package_id'],
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

  Map<String, dynamic> toJson() {
    return {
      'source': source?.toJson(),
      'destination': destination?.toJson(),
      'trip_type': tripType,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'search_tags': searchTags,
      if (packageId != null) 'package_id': packageId,
      'one_way_distance': oneWayDistance,
      'is_instant_search': isInstantSearch,
      'trip_type_details': tripTypeDetails?.toJson(),
      'previousTripCode': previousTripCode,
      'currentTripCode': currentTripCode,
      'search_id': searchId,
      'distance_booked': distanceBooked,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'features': features?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'vehicle_icons': vehicleIcons,
      'vehicle': vehicle,
      'driver': driver,
      'services': services,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'seller_discount': sellerDiscount,
      'per_km_charge': perKmCharge,
      'per_km_extra_charge': perKmExtraCharge,
      'total_driver_charges': totalDriverCharges,
      'base_fare': baseFare,
      'extra_time_fare': extraTimeFare?.toJson(),
      'extra_charges': extraCharges?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'applicable_time': applicableTime,
    };
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
      nightCharges: json['night_charges'] != null ? ChargeDetail.fromJson(json['night_charges']) : null,
      tollCharges: json['toll_charges'] != null ? ChargeDetail.fromJson(json['toll_charges']) : null,
      stateTax: json['state_tax'] != null ? ChargeDetail.fromJson(json['state_tax']) : null,
      parkingCharges: json['parking_charges'] != null ? ChargeDetail.fromJson(json['parking_charges']) : null,
      waitingCharges: json['waiting_charges'] != null ? WaitingCharges.fromJson(json['waiting_charges']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'night_charges': nightCharges?.toJson(),
      'toll_charges': tollCharges?.toJson(),
      'state_tax': stateTax?.toJson(),
      'parking_charges': parkingCharges?.toJson(),
      'waiting_charges': waitingCharges?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'is_included_in_base_fare': isIncludedInBaseFare,
      'is_included_in_grand_total': isIncludedInGrandTotal,
      'applicable_time_from': applicableTimeFrom,
      'applicable_time_till': applicableTimeTill,
      'is_applicable': isApplicable,
    };
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
    isApplicable: isApplicable,
  );

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

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'free_waiting_time': freeWaitingTime,
      'applicable_time': applicableTime,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'price': price?.toJson(),
      '_id': id,
      'countryName': countryName,
      'name': name,
      'title': title,
      'img': img,
      'description': description,
      'isActive': isActive,
      'baseCurrency': baseCurrency,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'daily': daily,
      'maximum': maximum,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'ratePoints': ratePoints,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'basic_trip_type': basicTripType,
      'airport_type': airportType,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'applicable': applicable,
      'message': message,
    };
  }
}